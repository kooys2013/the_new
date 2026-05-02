#!/usr/bin/env bash
# harness-daily-brief.sh — SessionStart 훅 (1일 1회)
# 스킬 사용률 / 바선생 6축 / obs 3축 이벤트 / Phase 2-3 도구 / 하네스 건강도 통합 리포트
# 원칙: <3s, 오늘 이미 실행 시 skip, silent exit 0
#
# ═══════════════════════════════════════════════════════════════════
# DEPRECATED 26/04/18 — superseded by 2604181800_daily-fit-check.sh
# 사유: SessionStart 동기 실행 5.64초 (ping×2s 타임아웃 2회) — 세션 지연 유발
# 교체: Layer 1 경량 체크(≤30s) + Layer 2 심층 분석(22:45 Task Scheduler)
# 설계: plans/velvet-yawning-pixel.md "Daily Fit Loop 1-B"
# 참조 중인 문서/캐시 깨짐 방지를 위해 파일 자체는 유지, 즉시 exit 0
# ═══════════════════════════════════════════════════════════════════
exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

TODAY=$(date +%Y%m%d)
CACHE_DIR="$HOME/.claude/_cache"
HARNESS_DIR="$CACHE_DIR/harness"
FLAG_FILE="$HARNESS_DIR/brief-${TODAY}.flag"
mkdir -p "$HARNESS_DIR" 2>/dev/null || exit 0

# 오늘 이미 실행됨 → skip
[ -f "$FLAG_FILE" ] && exit 0
touch "$FLAG_FILE" 2>/dev/null || exit 0

# 7일 이상 된 flag 정리
find "$HARNESS_DIR" -name "brief-*.flag" -mtime +7 -delete 2>/dev/null || true

export CACHE_DIR HARNESS_DIR
export HISTORY="${CLAUDE_HISTORY:-$HOME/.claude/history.jsonl}"

python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, re, pathlib, datetime, sys, subprocess

today = datetime.date.today()
week_ago = today - datetime.timedelta(days=7)
cache_dir = pathlib.Path(os.environ.get("CACHE_DIR", ""))
harness_dir = pathlib.Path(os.environ.get("HARNESS_DIR", ""))
history_path = os.environ.get("HISTORY", "")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. 스킬 사용 통계 (history.jsonl 최근 1000줄)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
skill_counts = {}
generator_counts = {}
try:
    with open(history_path, encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()[-1000:]
    for line in lines:
        try:
            text = line  # raw JSON line (no full parse for speed)
            # Skill tool 호출: "skill": "xxx"
            for m in re.findall(r'"skill"\s*:\s*"([^"]+)"', text):
                skill_counts[m] = skill_counts.get(m, 0) + 1
            # generator 스킬
            for m in re.findall(r'"([a-z-]+-generator)"', text, re.IGNORECASE):
                generator_counts[m.lower()] = generator_counts.get(m.lower(), 0) + 1
        except Exception:
            pass
except Exception:
    pass

top_skills = sorted(skill_counts.items(), key=lambda x: -x[1])[:6]
total_skill_calls = sum(skill_counts.values())

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. obs JSONL — 3축 이벤트 집계 (7일)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
obs_dir = pathlib.Path.home() / ".claude" / "_cache" / "obs"
event_totals = {}
drift_warn = 0; drift_info = 0
req_tags = 0; ux_suggests = 0
session_count = 0

if obs_dir.exists():
    for jl in sorted(obs_dir.glob("*.jsonl"))[-5:]:
        try:
            for line in jl.read_text(encoding="utf-8", errors="ignore").splitlines():
                try:
                    ev = json.loads(line)
                    ts = ev.get("ts", "")
                    try:
                        if datetime.date.fromisoformat(ts[:10]) < week_ago:
                            continue
                    except Exception:
                        pass
                    ev_name = ev.get("event", "")
                    event_totals[ev_name] = event_totals.get(ev_name, 0) + 1
                    if ev_name == "session-start":
                        session_count += 1
                    elif ev_name == "drift-detect":
                        sev = ev.get("severity", "info")
                        if sev in ("warn", "critical"):
                            drift_warn += 1
                        else:
                            drift_info += 1
                    elif ev_name == "trace-prompt-tag":
                        req_tags += 1
                    elif ev_name == "ux-suggest":
                        ux_suggests += 1
                except Exception:
                    pass
        except Exception:
            pass

total_obs = sum(event_totals.values())

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. 바선생 (vibe-sunsang) 6축 현황
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vibe_last = ""
vibe_pending = False
timeline_path = pathlib.Path.home() / "vibe-sunsang" / "growth-log" / "TIMELINE.md"
if timeline_path.exists():
    try:
        tail = timeline_path.read_text(encoding="utf-8", errors="ignore").splitlines()[-50:]
        for line in reversed(tail):
            if re.search(r'L[0-9]', line):
                vibe_last = line.strip()[:80]
                break
    except Exception:
        pass

pending_path = cache_dir / "weekly-fit-pending.md"
vibe_pending = pending_path.exists()

# sessions.jsonl — 최근 세션 품질 이력
sessions_file = harness_dir / "sessions.jsonl"
recent_skills_rate = 0.0
if sessions_file.exists():
    try:
        sess_lines = sessions_file.read_text(encoding="utf-8", errors="ignore").splitlines()[-30:]
        sessions_with_skills = sum(
            1 for l in sess_lines
            if json.loads(l).get("skill_count", 0) > 0
        )
        if sess_lines:
            recent_skills_rate = sessions_with_skills / len(sess_lines) * 100
    except Exception:
        pass

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. Phase 2/3 도구 상태
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def check_tool(name):
    try:
        result = subprocess.run(["which", name], capture_output=True, timeout=1)
        return result.returncode == 0
    except Exception:
        return False

def check_py(mod):
    try:
        r = subprocess.run(
            ["python3", "-c", f"import {mod}"],
            capture_output=True, timeout=2
        )
        return r.returncode == 0
    except Exception:
        return False

def ping_local(url):
    import urllib.request
    try:
        urllib.request.urlopen(url, timeout=1)
        return True
    except Exception:
        return False

oasdiff_ok  = check_tool("oasdiff") or (pathlib.Path.home() / "go" / "bin" / "oasdiff").exists()
pytestarch_ok = check_py("pytestarch")
mlfinlab_ok = check_py("mlfinlab")
langfuse_ok = ping_local("http://localhost:3000/api/health")
phoenix_ok  = ping_local("http://localhost:6006")
checkly_ok  = check_tool("checkly")
tracetest_ok = check_tool("tracetest") or (pathlib.Path.home() / ".local" / "bin" / "tracetest").exists()

ph2_score = sum([oasdiff_ok, pytestarch_ok, mlfinlab_ok]) / 3 * 100
ph3_score = sum([langfuse_ok, phoenix_ok, checkly_ok, tracetest_ok]) / 4 * 100

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. 하네스 건강도 종합 점수
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 가중치: 스킬사용(30) + obs이벤트(20) + 세션빈도(20) + Phase2/3(15) + vibe(15)
skill_score   = min(100, total_skill_calls / max(session_count, 1) * 20)  # 세션당 5회 = 100점
obs_score     = min(100, total_obs / max(session_count, 1) * 10)          # 세션당 10이벤트 = 100점
session_score = min(100, session_count / 14 * 100)                        # 주 2회 = 100점
tool_score    = (ph2_score + ph3_score) / 2
vibe_score    = 70 if vibe_last else 0  # 기본 70, 데이터 없으면 0

health = int(
    skill_score * 0.30 +
    obs_score   * 0.20 +
    session_score * 0.20 +
    tool_score  * 0.15 +
    vibe_score  * 0.15
)

if health >= 80:
    health_emoji = "🟢"
    health_label = "우수"
elif health >= 60:
    health_emoji = "🟡"
    health_label = "양호"
elif health >= 40:
    health_emoji = "🟠"
    health_label = "개선 필요"
else:
    health_emoji = "🔴"
    health_label = "위험"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. 개선 권고 (최대 4개)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
recs = []
if total_skill_calls == 0:
    recs.append("스킬 미사용 — /skill 활용 권장 (skill-quickref.md 참조)")
elif skill_score < 40:
    recs.append(f"스킬 사용 저조 ({total_skill_calls}회/{session_count}세션) — ORCH 축 개선")
if drift_warn >= 3:
    recs.append(f"drift warn {drift_warn}건 — /skill drift-sentinel 심층 분석")
if vibe_pending:
    recs.append("주간 FIT 제안 대기 — apply-weekly-fit.sh <A|B|C> 선택")
if not pytestarch_ok:
    recs.append("pip install pytestarch  (아키텍처 가드 Phase 2)")
if not oasdiff_ok:
    recs.append("go install github.com/tufin/oasdiff@latest  (API diff Phase 2)")
if not langfuse_ok:
    recs.append("docker compose -f ~/.claude/_cache/langfuse/docker-compose.yml up -d")
if req_tags == 0 and session_count > 2:
    recs.append("REQ-ID 태깅 0건 — 트레이서빌리티 미활성 (traceability-contract.md)")

recs = recs[:4]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. 출력 조립
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def mk_bar(n, total, w=10):
    if total == 0:
        return "░" * w
    filled = min(w, int(n / total * w))
    return "█" * filled + "░" * (w - filled)

out_lines = []
out_lines.append(f"┌─── Harness Daily [{today}] {health_emoji} {health}점 ({health_label}) {'─'*12}┐")
out_lines.append(f"│  세션(7d): {session_count:>2} | 스킬호출: {total_skill_calls:>3} | obs이벤트: {total_obs:>3}          │")
out_lines.append(f"│  drift warn: {drift_warn} | REQ태그: {req_tags} | UX권고: {ux_suggests}                     │")

# 바선생 상태
out_lines.append("│                                                            │")
if vibe_last:
    out_lines.append(f"│  🎓 바선생: {vibe_last[:52]:<52} │")
else:
    out_lines.append("│  🎓 바선생: vibe-sunsang 데이터 없음 (~/vibe-sunsang/    │")
if vibe_pending:
    out_lines.append("│      ⚡ 주간 FIT 제안 대기 → apply-weekly-fit.sh <A|B|C>  │")

# 스킬 TOP
out_lines.append("│                                                            │")
out_lines.append("│  📊 스킬 사용 TOP (최근)                                   │")
if top_skills:
    max_cnt = top_skills[0][1]
    for sk, cnt in top_skills:
        bar = mk_bar(cnt, max_cnt, 8)
        sk_s = sk[:22]
        out_lines.append(f"│    {sk_s:<22} {bar} {cnt:>3}회                 │")
else:
    out_lines.append("│    (기록 없음 — history.jsonl 스캔 필요)                   │")

# Phase 2/3 도구 상태
out_lines.append("│                                                            │")
p2 = f"oasdiff {'✅' if oasdiff_ok else '❌'} | pytestarch {'✅' if pytestarch_ok else '❌'} | mlfinlab {'✅' if mlfinlab_ok else '❌'}"
p3 = f"Langfuse {'✅' if langfuse_ok else '❌'} | Phoenix {'✅' if phoenix_ok else '❌'} | Checkly {'✅' if checkly_ok else '❌'} | Tracetest {'✅' if tracetest_ok else '❌'}"
out_lines.append(f"│  🔧 Phase 2: {p2:<46} │")
out_lines.append(f"│  🌐 Phase 3: {p3:<46} │")

# 권고
if recs:
    out_lines.append("│                                                            │")
    out_lines.append("│  💡 개선 권고:                                             │")
    for r in recs:
        out_lines.append(f"│    → {r[:55]:<55} │")

out_lines.append("│  → 심층분석: /skill harness-health                        │")
out_lines.append("└" + "─" * 62 + "┘")

report = "\n".join(out_lines)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": report
    }
}))
PYEOF

obs_append harness-daily-brief info "{\"date\":\"$TODAY\",\"status\":\"reported\"}" 2>/dev/null || true
exit 0
