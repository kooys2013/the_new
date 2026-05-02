#!/usr/bin/env bash
# 2604181800_daily-fit-check.sh — SessionStart Layer 1 (경량 ≤30s)
# Daily Fit Loop 1-B: 캐시 hit 시 즉시 박스 브리핑, miss 시 경량 스캔 후 캐시 생성.
# 원칙: <30s 하드캡, silent exit 0, 외부 ping/docker/curl 금지.

# Windows cp949 기본 인코딩 우회 — 이모지/한글 출력 안정화
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

HARNESS_DIR="$HOME/.claude/_cache/harness"
REPORT_DIR="$HOME/.claude/_report"
mkdir -p "$HARNESS_DIR" 2>/dev/null || exit 0

TODAY=$(date +%y%m%d)
CACHE_FILE="$HARNESS_DIR/daily-fit-${TODAY}.json"
FLAG_FILE="$HARNESS_DIR/daily-fit-${TODAY}.flag"

export HARNESS_DIR REPORT_DIR CACHE_FILE FLAG_FILE TODAY

# 드레인: 플래그가 있으면 brief만 출력하고 즉시 종료 (≤1s)
if [ -f "$FLAG_FILE" ] && [ -f "$CACHE_FILE" ]; then
    python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, sys
cache = os.environ.get("CACHE_FILE", "")
try:
    with open(cache, encoding="utf-8") as f:
        data = json.load(f)
    brief = data.get("brief", "")
    if brief:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": brief
            }
        }))
except Exception:
    pass
PYEOF
    exit 0
fi

# 캐시 miss — 경량 스캔 (Python stdlib만, 외부 IO 없음)
# 30s 하드캡: Python timeout 25s로 제한
export OBS_DIR="${OBS_DIR:-$HOME/.claude/_cache/obs}"
timeout 25 python3 - 2>/dev/null <<'PYEOF'
import json, os, pathlib, datetime, re, glob, sys

harness_dir = pathlib.Path(os.environ.get("HARNESS_DIR", ""))
obs_dir = pathlib.Path(os.environ.get("OBS_DIR", ""))
cache_file = os.environ.get("CACHE_FILE", "")
flag_file = os.environ.get("FLAG_FILE", "")
report_dir = pathlib.Path(os.environ.get("REPORT_DIR", ""))
today = os.environ.get("TODAY", "")

now = datetime.datetime.now()
sessions_path = harness_dir / "sessions.jsonl"

# 1. 최근 7일 sessions.jsonl 집계 (최대 500줄 — 경량)
skill_count_7d = 0
quality_sum = 0
quality_n = 0
top_skills = {}
has_verify_n = 0
sessions_7d = 0

try:
    if sessions_path.exists():
        lines = sessions_path.read_text(encoding="utf-8").splitlines()[-500:]
        cutoff = (now - datetime.timedelta(days=7)).strftime("%Y-%m-%d")
        for line in lines:
            try:
                rec = json.loads(line)
            except Exception:
                continue
            if rec.get("date", "") < cutoff:
                continue
            sessions_7d += 1
            skill_count_7d += rec.get("skill_count", 0)
            qs = rec.get("quality_score", 0)
            if qs:
                quality_sum += qs
                quality_n += 1
            if rec.get("has_verification"):
                has_verify_n += 1
            for s in rec.get("skills", []):
                top_skills[s] = top_skills.get(s, 0) + 1
except Exception:
    pass

avg_quality = round(quality_sum / quality_n) if quality_n else 0
verify_pct = round(100 * has_verify_n / sessions_7d) if sessions_7d else 0
top3 = sorted(top_skills.items(), key=lambda x: -x[1])[:3]
top3_str = " / ".join(f"{s}({n})" for s, n in top3) if top3 else "(없음)"

# 2. 어제자 리포트 요약 (있으면)
yesterday_brief = ""
try:
    pattern = str(report_dir / f"*{(now - datetime.timedelta(days=1)).strftime('%y%m%d')}*_daily_fit.md")
    matches = sorted(glob.glob(pattern))
    if matches:
        with open(matches[-1], encoding="utf-8") as f:
            head = f.read(500)
        # Summary 섹션 1줄 추출
        m = re.search(r"##\s*1\.\s*Summary\s*\n+(.+?)(?:\n\n|\n##)", head, re.DOTALL)
        if m:
            yesterday_brief = m.group(1).strip().replace("\n", " ")[:80]
except Exception:
    pass

# 3. DNA mutation 오늘자 pick (있으면)
mutation_today = ""
mutation_path = harness_dir / f"mutation-{today}.json"
try:
    if mutation_path.exists():
        with open(mutation_path, encoding="utf-8") as f:
            m = json.load(f)
        pick = m.get("pick") or {}
        if pick:
            mutation_today = f"{pick.get('code', '?')} → {pick.get('target', '?')}"
except Exception:
    pass

# 4. obs 주간 이벤트 카운트
try:
    week = now.strftime("%G-%V")
    obs_file = obs_dir / f"{week}.jsonl"
    if obs_file.exists():
        obs_count = sum(1 for _ in obs_file.read_text(encoding="utf-8").splitlines())
    else:
        obs_count = 0
except Exception:
    obs_count = 0

# 5. 박스 브리핑 생성 (10줄 이내)
brief_lines = [
    "┌─── Daily Fit (Layer 1) ───────────────────────┐",
    f"│ 7일: 세션 {sessions_7d} | 스킬 {skill_count_7d}회 | Q{avg_quality} | 검증 {verify_pct}%",
    f"│ TOP3: {top3_str[:60]}",
    f"│ obs 주간 이벤트: {obs_count}건",
]
if yesterday_brief:
    brief_lines.append(f"│ 어제 요약: {yesterday_brief[:60]}")
if mutation_today:
    brief_lines.append(f"│ 🧬 DNA 제안: {mutation_today[:60]}")
    brief_lines.append(f"│ 승인: apply-daily-fit.sh (자세히는 /daily-fit-engine)")
else:
    brief_lines.append("│ 🧬 오늘 DNA 제안: 없음 (22:45 analyzer 대기)")
brief_lines.append("└───────────────────────────────────────────────┘")

brief = "\n".join(brief_lines)

# 6. 캐시 저장 + 플래그
data = {
    "date": today,
    "generated_at": now.isoformat(),
    "sessions_7d": sessions_7d,
    "skill_count_7d": skill_count_7d,
    "avg_quality": avg_quality,
    "verify_pct": verify_pct,
    "top_skills": top3,
    "obs_weekly": obs_count,
    "yesterday_brief": yesterday_brief,
    "mutation_pick": mutation_today,
    "brief": brief,
}

try:
    with open(cache_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    pathlib.Path(flag_file).touch()
except Exception:
    pass

# 7. additionalContext 출력
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": brief
    }
}))

# 8. 오래된 캐시 prune (7일 경과)
try:
    cutoff_ts = (now - datetime.timedelta(days=7)).timestamp()
    for p in harness_dir.glob("daily-fit-*.json"):
        if p.stat().st_mtime < cutoff_ts:
            p.unlink(missing_ok=True)
    for p in harness_dir.glob("daily-fit-*.flag"):
        if p.stat().st_mtime < cutoff_ts:
            p.unlink(missing_ok=True)
except Exception:
    pass
PYEOF
PYRC=$?

# 타임아웃 or Python 실패 시 stub 로그만 기록 (세션 블로킹 방지)
if [ $PYRC -ne 0 ]; then
    obs_append daily-fit-check-timeout warn '{"phase":"layer1","rc":"'"$PYRC"'"}' 2>/dev/null || true
fi

# obs 이벤트 기록
obs_append daily-fit-check info "{\"cached\":$([ -f "$FLAG_FILE" ] && echo true || echo false),\"rc\":$PYRC}" 2>/dev/null || true

exit 0
