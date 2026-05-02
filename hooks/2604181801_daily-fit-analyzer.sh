#!/usr/bin/env bash
# 2604181801_daily-fit-analyzer.sh — Layer 2 심층 분석 (Task Scheduler 22:45, ≤5m 하드캡)
# Daily Fit Loop 1-B: 30일 sessions.jsonl + obs/*.jsonl 풀스캔 → 자산 라이프사이클 → DNA mutation 1건 → 리포트.
# 원칙: 독립 실행 (Claude Code 훅 아님), ≤5m 하드캡, silent exit 0.
#
# Usage:
#   bash ~/.claude/hooks/2604181801_daily-fit-analyzer.sh         # 수동 실행
#   schtasks /run /tn claude-daily-fit-deep                        # Task Scheduler

# Windows cp949 기본 인코딩 우회 — 이모지/한글 출력 안정화
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

HARNESS_DIR="$HOME/.claude/_cache/harness"
REPORT_DIR="$HOME/.claude/_report"
REPORT_ARCHIVE="$REPORT_DIR/archive"
TEMPLATE="$REPORT_DIR/_TEMPLATE_daily_fit.md"
SKILLS_DIR="$HOME/.claude/skills"
RULES_DIR="$HOME/.claude/rules"
HOOKS_DIR="$HOME/.claude/hooks"
OBS_DIR="${CLAUDE_OBS_DIR:-$HOME/.claude/_cache/obs}"

mkdir -p "$HARNESS_DIR" "$REPORT_DIR" "$REPORT_ARCHIVE" 2>/dev/null || exit 0

# 일요일은 weekly-fit-analyzer (22:00)와 충돌 방지 — 22:45에는 skip
DOW=$(date +%u)  # 1=Mon..7=Sun
if [ "$DOW" = "7" ]; then
    obs_append daily-fit-skip info '{"reason":"sunday-weekly-conflict"}' 2>/dev/null || true
    exit 0
fi

TODAY=$(date +%y%m%d)
STAMP=$(date +%y%m%dT%H%M)
REPORT_FILE="$REPORT_DIR/${STAMP}_daily_fit.md"
MUTATION_FILE="$HARNESS_DIR/mutation-${TODAY}.json"
LIFECYCLE_FILE="$HARNESS_DIR/lifecycle-${TODAY}.json"

export HARNESS_DIR REPORT_DIR REPORT_ARCHIVE TEMPLATE SKILLS_DIR RULES_DIR HOOKS_DIR OBS_DIR
export TODAY STAMP REPORT_FILE MUTATION_FILE LIFECYCLE_FILE

# 5분 하드캡
timeout 300 python3 - 2>/dev/null <<'PYEOF'
import json, os, re, pathlib, datetime, glob, shutil, sys
from collections import Counter, defaultdict

harness_dir = pathlib.Path(os.environ["HARNESS_DIR"])
report_dir = pathlib.Path(os.environ["REPORT_DIR"])
report_archive = pathlib.Path(os.environ["REPORT_ARCHIVE"])
template = pathlib.Path(os.environ["TEMPLATE"])
skills_dir = pathlib.Path(os.environ["SKILLS_DIR"])
rules_dir = pathlib.Path(os.environ["RULES_DIR"])
hooks_dir = pathlib.Path(os.environ["HOOKS_DIR"])
obs_dir = pathlib.Path(os.environ["OBS_DIR"])

today = os.environ["TODAY"]
stamp = os.environ["STAMP"]
report_file = pathlib.Path(os.environ["REPORT_FILE"])
mutation_file = pathlib.Path(os.environ["MUTATION_FILE"])
lifecycle_file = pathlib.Path(os.environ["LIFECYCLE_FILE"])

now = datetime.datetime.now()
today_dt = now.date()

# ── PHASE 1: 30일 sessions.jsonl 풀스캔 ──
sessions_path = harness_dir / "sessions.jsonl"
sessions_30d = []
skill_count_30d = Counter()
skill_last_ref = {}
quality_scores = []
has_verify_n = 0
has_edit_n = 0
cutoff_30d = (now - datetime.timedelta(days=30)).strftime("%Y-%m-%d")
cutoff_7d = (now - datetime.timedelta(days=7)).strftime("%Y-%m-%d")
skill_7d_count = Counter()
skill_prev_7d_count = Counter()
cutoff_prev_7d = (now - datetime.timedelta(days=14)).strftime("%Y-%m-%d")

try:
    if sessions_path.exists():
        for line in sessions_path.read_text(encoding="utf-8").splitlines():
            try:
                rec = json.loads(line)
            except Exception:
                continue
            d = rec.get("date", "")
            if d < cutoff_30d:
                continue
            sessions_30d.append(rec)
            if rec.get("has_verification"):
                has_verify_n += 1
            if rec.get("has_edit"):
                has_edit_n += 1
            qs = rec.get("quality_score", 0)
            if qs:
                quality_scores.append(qs)
            for s in rec.get("skills", []):
                skill_count_30d[s] += 1
                if d > skill_last_ref.get(s, ""):
                    skill_last_ref[s] = d
                if d >= cutoff_7d:
                    skill_7d_count[s] += 1
                elif d >= cutoff_prev_7d:
                    skill_prev_7d_count[s] += 1
except Exception:
    pass

# ── PHASE 1-B: obs 30일 집계 ──
obs_events = Counter()
obs_severity = Counter()
obs_hook_fires = Counter()
try:
    for i in range(5):  # 최근 5주
        week_date = now - datetime.timedelta(weeks=i)
        week_str = week_date.strftime("%G-%V")
        obs_file = obs_dir / f"{week_str}.jsonl"
        if obs_file.exists():
            for line in obs_file.read_text(encoding="utf-8").splitlines():
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                ts = rec.get("ts", "")
                if ts < cutoff_30d:
                    continue
                ev = rec.get("event", "unknown")
                obs_events[ev] += 1
                obs_severity[rec.get("severity", "info")] += 1
                # 훅 이벤트 추론 (event가 훅명 prefix와 유사하면)
                obs_hook_fires[ev] += 1
except Exception:
    pass

# ── PHASE 2: 자산 인벤토리 + 라이프사이클 ──
def scan_assets(base_dir, pattern="**/*"):
    results = []
    try:
        for p in base_dir.glob(pattern):
            if not p.is_file():
                continue
            # archive/ 제외
            if "archive" in p.parts:
                continue
            if "_lib" in p.parts or "_setup" in p.parts:
                continue
            results.append(p)
    except Exception:
        pass
    return results

all_skills = [p for p in scan_assets(skills_dir, "*/SKILL.md")]
all_hooks = [p for p in scan_assets(hooks_dir, "*.sh")]
all_rules = [p for p in scan_assets(rules_dir, "*.md")]

REINF_PATTERN = re.compile(r"\[reinforced:([^\]]+)\]")

def parse_date(s):
    """YY/MM/DD or YYMMDD → datetime.date"""
    s = s.strip()
    try:
        if "/" in s:
            parts = s.split("/")
            return datetime.date(2000 + int(parts[0]), int(parts[1]), int(parts[2]))
        elif len(s) == 6:
            return datetime.date(2000 + int(s[:2]), int(s[2:4]), int(s[4:6]))
    except Exception:
        return None
    return None

def last_reinforced(path):
    """파일 내 [reinforced:...] 태그에서 최신 일자 추출"""
    try:
        content = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None, 0

    dates = []
    for m in REINF_PATTERN.finditer(content):
        for d_str in m.group(1).split(","):
            d = parse_date(d_str)
            if d:
                dates.append(d)
    if not dates:
        return None, 0

    latest = max(dates)
    # 최근 60일 내 태그 개수
    cutoff_60 = today_dt - datetime.timedelta(days=60)
    recent_count = sum(1 for d in dates if d >= cutoff_60)
    return latest, recent_count

def asset_last_ref(name, kind):
    """실제 참조된 마지막 일자 추정"""
    if kind == "skill":
        d = skill_last_ref.get(name)
        if d:
            try:
                return datetime.date.fromisoformat(d)
            except Exception:
                pass
    # fallback: mtime
    return None

def classify(path, kind, name):
    latest_tag, recent_count = last_reinforced(path)
    last_ref = asset_last_ref(name, kind) or latest_tag

    if last_ref is None:
        # mtime fallback
        try:
            last_ref = datetime.date.fromtimestamp(path.stat().st_mtime)
        except Exception:
            last_ref = today_dt

    days_since = (today_dt - last_ref).days
    if days_since >= 150:
        state = "candidate-archive"
    elif days_since >= 60:
        state = "dormant"
    else:
        state = "active"

    if recent_count >= 3:
        state += "+candidate-promote"

    return {
        "name": name,
        "path": str(path.relative_to(pathlib.Path.home() / ".claude")),
        "last_ref": last_ref.isoformat() if last_ref else None,
        "days_since": days_since,
        "state": state,
        "reinforced_60d": recent_count,
    }

lifecycle = {"active": [], "dormant": [], "candidate_archive": [], "candidate_promote": []}

for p in all_skills:
    info = classify(p, "skill", p.parent.name)
    key = info["state"]
    if "candidate-archive" in key:
        lifecycle["candidate_archive"].append(info)
    elif "dormant" in key:
        lifecycle["dormant"].append(info)
    else:
        lifecycle["active"].append(info)
    if "candidate-promote" in key:
        lifecycle["candidate_promote"].append(info)

for p in all_hooks:
    info = classify(p, "hook", p.stem)
    key = info["state"]
    if "candidate-archive" in key:
        lifecycle["candidate_archive"].append(info)
    elif "dormant" in key:
        lifecycle["dormant"].append(info)
    else:
        lifecycle["active"].append(info)

for p in all_rules:
    info = classify(p, "rule", p.stem)
    key = info["state"]
    if "candidate-archive" in key:
        lifecycle["candidate_archive"].append(info)
    elif "dormant" in key:
        lifecycle["dormant"].append(info)
    else:
        lifecycle["active"].append(info)
    if "candidate-promote" in key:
        lifecycle["candidate_promote"].append(info)

# lifecycle 저장
try:
    lifecycle_file.write_text(json.dumps({
        "date": today_dt.isoformat(),
        **{k: v for k, v in lifecycle.items()}
    }, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
except Exception:
    pass

# ── PHASE 3: DNA Mutation 후보 선정 ──
PRIO = {"P": 1, "D": 2, "R": 3, "A": 4}
candidates = []

# P 후보 — candidate-archive 중 hook 발동 0 (의미 있는 기간)
for info in lifecycle["candidate_archive"]:
    score = info["days_since"] * 0.1
    candidates.append({"code": "P", "target": info["path"], "reason": f"{info['days_since']}일 미참조 + archive 승격", "score": score, "asset": info})

# P 후보 — candidate-promote
for info in lifecycle["candidate_promote"]:
    score = info["reinforced_60d"] * 2.0
    candidates.append({"code": "P", "target": info["path"], "reason": f"[reinforced:] {info['reinforced_60d']}회 / 60일 → Core DNA 승격", "score": score, "asset": info})

# D 후보 — active 중 적중률 <5% (30일 참조 0)
for info in lifecycle["active"]:
    name = info["name"]
    hits = skill_count_30d.get(name, 0)
    if hits == 0 and info["days_since"] >= 30:
        score = 5.0 + info["days_since"] * 0.02
        candidates.append({"code": "D", "target": info["path"], "reason": f"30일 호출 0회 → dormant 강등", "score": score, "asset": info})

# R 후보 — 전주比 -50% 급락
for skill, prev in skill_prev_7d_count.items():
    curr = skill_7d_count.get(skill, 0)
    if prev >= 2 and curr <= prev * 0.5:
        score = (prev - curr) * 1.5
        candidates.append({"code": "R", "target": f"skills/{skill}/SKILL.md", "reason": f"전주比 {curr}/{prev} = -{int(100*(prev-curr)/prev)}% 급락", "score": score, "asset": None})

# A 후보 — dormant 자산에 7일 내 참조
for info in lifecycle["dormant"]:
    name = info["name"]
    if skill_7d_count.get(name, 0) > 0:
        candidates.append({"code": "A", "target": info["path"], "reason": f"dormant 자산에 최근 참조 → resurrect", "score": 10.0, "asset": info})

# 우선순위 정렬
candidates.sort(key=lambda c: (PRIO[c["code"]], -c["score"]))
pick = candidates[0] if candidates else None

mutation_data = {
    "date": today_dt.isoformat(),
    "pick": pick,
    "candidates": candidates[:5],  # TOP 5만 저장
    "apply_command": f"bash ~/.claude/hooks/_setup/apply-daily-fit.sh {pick['code']} {pick['target']}" if pick else "",
}

try:
    mutation_file.write_text(json.dumps(mutation_data, ensure_ascii=False, indent=2, default=str), encoding="utf-8")
except Exception:
    pass

# ── PHASE 4: 리포트 생성 ──
avg_quality = round(sum(quality_scores) / len(quality_scores)) if quality_scores else 0
median_quality = sorted(quality_scores)[len(quality_scores)//2] if quality_scores else 0
verify_pct = round(100 * has_verify_n / len(sessions_30d)) if sessions_30d else 0

# TOP 5 스킬
top_skills_30d = skill_count_30d.most_common(5)
# 미사용 스킬
used_skill_names = set(skill_count_30d.keys())
all_skill_names = set(p.parent.name for p in all_skills)
unused_skills = sorted(all_skill_names - used_skill_names)

# 훅 발동 TOP / 0건
hook_fire_top = obs_events.most_common(5)

# Phase 2/3 도구 상태
def tool_status(cmd):
    import subprocess
    try:
        r = subprocess.run(["which", cmd], capture_output=True, text=True, timeout=1)
        return "✅" if r.returncode == 0 else "❌"
    except Exception:
        return "❓"

tools_status = {
    "oasdiff": tool_status("oasdiff"),
    "pytestarch": tool_status("pytestarch"),
    "checkly": tool_status("checkly"),
    "tracetest": tool_status("tracetest"),
}

# Vibe 6축 (존재 시만)
vibe_timeline = pathlib.Path.home() / "vibe-sunsang" / "growth-log" / "TIMELINE.md"
vibe_summary = "N/A (vibe-sunsang 미설치)"
if vibe_timeline.exists():
    try:
        lines = vibe_timeline.read_text(encoding="utf-8").splitlines()[-30:]
        vibe_summary = "\n".join(lines[-6:])
    except Exception:
        pass
else:
    # stub 생성
    try:
        (harness_dir / "vibe-stub.md").write_text(
            "# vibe-sunsang placeholder\n\n설치 후 ~/vibe-sunsang/growth-log/TIMELINE.md 생성 필요.\n",
            encoding="utf-8"
        )
    except Exception:
        pass

# GO v2
cwd = pathlib.Path.cwd()
go_v2 = "N/A"
if (cwd / "go-v2").exists() or (cwd / "go_v2").exists():
    go_v2 = "감지됨 — CPCV 분기 활성화 필요"

# 템플릿 로드 or fallback 생성
if template.exists():
    try:
        tpl = template.read_text(encoding="utf-8")
    except Exception:
        tpl = None
else:
    tpl = None

if not tpl:
    # fallback 템플릿
    tpl = """# Daily Fit Report — {{STAMP}}

## 1. Summary
- 30일: 세션 {{SESSIONS_30D}} / 스킬 {{SKILL_COUNT_30D}}회
- 평균 품질: Q{{AVG_QUALITY}} (중앙값 {{MEDIAN_QUALITY}}) / 검증률 {{VERIFY_PCT}}%

## 2. Skill Usage (TOP 5)
{{TOP_SKILLS}}

미사용 스킬 ({{UNUSED_COUNT}}개): {{UNUSED_SKILLS}}

## 3. Hook Activity
{{HOOK_TOP}}

## 4. Rule Hits
{{RULE_HITS}}

## 5. Asset Lifecycle
- active: {{ACTIVE_COUNT}} / dormant: {{DORMANT_COUNT}} / candidate-archive: {{CAND_ARCH_COUNT}} / candidate-promote: {{CAND_PROM_COUNT}}

### Dormant (최근 전이)
{{DORMANT_LIST}}

### Candidate-Archive
{{CAND_ARCH_LIST}}

## 6. DNA Mutation 후보
{{MUTATION_PICK}}

TOP 5 후보:
{{CANDIDATES_LIST}}

## 7. Vibe 6축
```
{{VIBE_SUMMARY}}
```

## 8. Phase 2/3 도구 상태
{{TOOLS_STATUS}}

GO v2: {{GO_V2}}

## 9. 승인 명령

```bash
{{APPLY_CMD}}
```

---

생성: {{GENERATED_AT}} / analyzer v1.0
"""

def fmt_top_skills(top):
    if not top:
        return "(30일 내 호출 없음)"
    return "\n".join(f"- {s}: {n}회" for s, n in top)

def fmt_list(items, limit=5):
    if not items:
        return "(없음)"
    return "\n".join(f"- {i.get('path', i.get('target', '?'))} ({i.get('days_since', '?')}일)" for i in items[:limit])

def fmt_candidates(cands):
    if not cands:
        return "(없음)"
    return "\n".join(f"- [{c['code']}] {c['target']} — {c['reason']} (score={c['score']:.1f})" for c in cands[:5])

def fmt_tools(d):
    return "\n".join(f"- {k}: {v}" for k, v in d.items())

replacements = {
    "{{STAMP}}": stamp,
    "{{SESSIONS_30D}}": str(len(sessions_30d)),
    "{{SKILL_COUNT_30D}}": str(sum(skill_count_30d.values())),
    "{{AVG_QUALITY}}": str(avg_quality),
    "{{MEDIAN_QUALITY}}": str(median_quality),
    "{{VERIFY_PCT}}": str(verify_pct),
    "{{TOP_SKILLS}}": fmt_top_skills(top_skills_30d),
    "{{UNUSED_COUNT}}": str(len(unused_skills)),
    "{{UNUSED_SKILLS}}": ", ".join(unused_skills[:10]) or "(없음)",
    "{{HOOK_TOP}}": "\n".join(f"- {e}: {n}" for e, n in hook_fire_top) or "(obs 이벤트 없음)",
    "{{RULE_HITS}}": f"reinforce-log 기반: (추후 구현 시 자세히)",
    "{{ACTIVE_COUNT}}": str(len(lifecycle["active"])),
    "{{DORMANT_COUNT}}": str(len(lifecycle["dormant"])),
    "{{CAND_ARCH_COUNT}}": str(len(lifecycle["candidate_archive"])),
    "{{CAND_PROM_COUNT}}": str(len(lifecycle["candidate_promote"])),
    "{{DORMANT_LIST}}": fmt_list(lifecycle["dormant"]),
    "{{CAND_ARCH_LIST}}": fmt_list(lifecycle["candidate_archive"]),
    "{{MUTATION_PICK}}": (
        f"**[{pick['code']}]** {pick['target']}\n- 사유: {pick['reason']}\n- 점수: {pick['score']:.1f}" if pick
        else "오늘 제안 없음 (모든 자산 안정)"
    ),
    "{{CANDIDATES_LIST}}": fmt_candidates(candidates),
    "{{VIBE_SUMMARY}}": vibe_summary[:800],
    "{{TOOLS_STATUS}}": fmt_tools(tools_status),
    "{{GO_V2}}": go_v2,
    "{{APPLY_CMD}}": mutation_data["apply_command"] or "# 오늘 제안 없음",
    "{{GENERATED_AT}}": now.isoformat(),
}

report_content = tpl
for k, v in replacements.items():
    report_content = report_content.replace(k, str(v))

try:
    report_file.write_text(report_content, encoding="utf-8")
except Exception as e:
    pass

# ── PHASE 5: Slack conditional + prune ──
slack_mode = os.environ.get("DAILY_FIT_SLACK", "conditional")
e_count = obs_severity.get("critical", 0)
h_count = obs_severity.get("warn", 0)

if slack_mode == "always" or (slack_mode == "conditional" and (e_count + h_count) >= 3):
    # slack-notify.sh 호출은 여기서는 플래그만 남김 (훅 체인 분리)
    try:
        (harness_dir / "slack-pending.flag").write_text(
            f"daily-fit:{today}:E{e_count}H{h_count}",
            encoding="utf-8"
        )
    except Exception:
        pass

# 오래된 리포트 prune (30일 경과 → archive)
cutoff_ts = (now - datetime.timedelta(days=30)).timestamp()
try:
    for p in report_dir.glob("*_daily_fit.md"):
        if p.name.startswith("_TEMPLATE"):
            continue
        if p.stat().st_mtime < cutoff_ts:
            shutil.move(str(p), str(report_archive / p.name))
    # mutation-*.json 30일 경과 삭제
    for p in harness_dir.glob("mutation-*.json"):
        if p.stat().st_mtime < cutoff_ts:
            p.unlink(missing_ok=True)
    for p in harness_dir.glob("lifecycle-*.json"):
        if p.stat().st_mtime < cutoff_ts:
            p.unlink(missing_ok=True)
except Exception:
    pass

# obs 이벤트
print(json.dumps({
    "status": "completed",
    "report": str(report_file),
    "mutation_picked": pick["code"] if pick else None,
    "sessions_30d": len(sessions_30d),
}))
PYEOF
PYRC=$?

# 타임아웃(124) or Python 실패 시 critical 이벤트 + exit 0 (체인 보호)
if [ $PYRC -ne 0 ]; then
    obs_append daily-fit-analyzer-timeout critical "{\"phase\":\"layer2\",\"rc\":$PYRC}" 2>/dev/null || true
    exit 0
fi

# obs 이벤트 기록
obs_append daily-fit-analyzed info "{\"report\":\"$STAMP\",\"rc\":$PYRC}" 2>/dev/null || true

exit 0
