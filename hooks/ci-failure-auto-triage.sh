#!/usr/bin/env bash
# ci-failure-auto-triage.sh — PostToolUse(Bash) 훅 (카테고리 C)
# 트리거: `git push` 또는 `gh run` Bash 호출 후
# 동작: gh run list 폴링 → failed 감지 → gh run view --log-failed
#       → /codex:review --model spark --effort low --background 위임 (review만, write 금지)
#       → _cache/codex-automations/ci-triage-RUNID.md 생성
# 원칙: <30s, silent exit 0, GREEN-only usage gate, write 0건

export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || true
type obs_init >/dev/null 2>&1 && obs_init

# 1. payload 파싱 — git push / gh run 명령만 처리
HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

CMD=$(python3 - 2>/dev/null <<'PYEOF'
import json, os
try:
    p = json.loads(os.environ.get("HOOK_PAYLOAD", "{}"))
    cmd = (p.get("tool_input", {}) or {}).get("command", "") or p.get("command", "")
    print(cmd[:500])
except Exception:
    print("")
PYEOF
)

# 트리거 키워드 매칭 (git push / gh run)
case "$CMD" in
    *"git push"*|*"gh run"*) ;;
    *) exit 0 ;;
esac

# 2. usage-gate GREEN 확인 (없으면 skip — fail-safe)
USAGE_LEVEL="${CLAUDE_USAGE_LEVEL:-GREEN}"
if [ "$USAGE_LEVEL" != "GREEN" ]; then
    type obs_event >/dev/null 2>&1 && obs_event "codex-automations" "ci-triage-skip" \
      '{"reason":"usage_gate_'"$USAGE_LEVEL"'","ts":"'$(date -Iseconds)'"}'
    exit 0
fi

# 3. gh CLI 가용 여부 확인
command -v gh >/dev/null 2>&1 || exit 0

OUTPUT_DIR="$HOME/.claude/_cache/codex-automations"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || exit 0

# 4. 최근 워크플로 상태 (5초 timeout)
RUN_INFO=$(timeout 5 gh run list --limit 1 --json databaseId,status,conclusion,name,headBranch,createdAt 2>/dev/null || echo "[]")
if [ -z "$RUN_INFO" ] || [ "$RUN_INFO" = "[]" ]; then
    exit 0
fi

export RUN_INFO OUTPUT_DIR

# 5. failed/cancelled 분기 + triage 파일 생성
TRIAGE_INFO=$(python3 - 2>/dev/null <<'PYEOF'
import json, os, sys, datetime, pathlib

raw = os.environ.get("RUN_INFO", "[]")
try:
    runs = json.loads(raw)
except Exception:
    sys.exit(0)

if not runs:
    sys.exit(0)

r = runs[0]
status = (r.get("status") or "").lower()
concl = (r.get("conclusion") or "").lower()
run_id = r.get("databaseId")

# 진행 중이거나 성공이면 skip (silent)
if concl not in ("failure", "cancelled", "timed_out"):
    sys.exit(0)

out_dir = pathlib.Path(os.environ["OUTPUT_DIR"])
triage_file = out_dir / f"ci-triage-{run_id}.md"

# 이미 존재하면 skip
if triage_file.exists():
    sys.exit(0)

now = datetime.datetime.now().isoformat(timespec="seconds")
lines = [
    f"# CI Triage — Run {run_id}",
    "",
    "> Evidence Rules (E1-E6) 준수.",
    "> 인용: `gh-run:{id}` / `log[ISO-8601]` / `commit:abc1234`",
    "> 라벨: `[observed]` / `[suspected]` / `[inferred]`",
    "",
    "## Summary",
    f"- Run ID: `gh-run:{run_id}` [observed]",
    f"- Status: **{concl}** (gh run list, {now}) [observed]",
    f"- Workflow: {r.get('name', 'Unknown')}",
    f"- Branch: `{r.get('headBranch', 'Unknown')}`",
    f"- Created: {r.get('createdAt', 'Unknown')}",
    "",
    "## Findings (초기)",
    f"- [observed] CI 실패 감지: `gh run list` 결과 conclusion={concl}",
    "- [suspected] 원인은 로그 분석 필요 — 아래 커맨드 실행 권장:",
    "",
    "```bash",
    f"gh run view {run_id} --log-failed",
    f"gh run view {run_id} --log",
    "```",
    "",
    "## Codex Review (위임 권장)",
    "",
    "쿼터 GREEN 상태에서 다음 명령으로 위임:",
    "",
    "```bash",
    f"gh run view {run_id} --log-failed | head -200 > /tmp/ci-fail-{run_id}.log",
    f"/codex:review --model spark --effort low --background \\",
    f"  --context /tmp/ci-fail-{run_id}.log",
    "```",
    "",
    "Codex 결과는 `_cache/codex-bg/`에 누적되며 다음 standup에 자동 인용됨.",
    "",
    "## Unknowns / Next Steps",
    "- Root cause: Unknown (자동 추출 미수행)",
    "  → next-step: 위 `gh run view --log-failed` 수동 실행 또는 Codex 위임",
    "- Breaking change 여부: Unknown",
    "  → next-step: drift-sentinel 스킬 호출로 API 시그니처 변경 점검",
    "",
    "## Scope-out",
    "- 본 triage는 **자동 RCA가 아닌 후보 제시**. 최종 판단은 사용자 권한.",
    "- NEVER: PR 자동 코멘트, 자동 fix commit (accumulated-lessons.md 준수)",
    "",
    "---",
    f"_생성: {now} | 비용: Codex API 호출 0건 (gh CLI만 사용)_",
]
triage_file.write_text("\n".join(lines), encoding="utf-8")
print(f"{run_id}|{concl}|{triage_file.name}")
PYEOF
)

if [ -n "$TRIAGE_INFO" ]; then
    RUN_ID=$(echo "$TRIAGE_INFO" | cut -d'|' -f1)
    CONCL=$(echo "$TRIAGE_INFO" | cut -d'|' -f2)
    FNAME=$(echo "$TRIAGE_INFO" | cut -d'|' -f3)

    # statusMessage 출력 (다음 응답에 1줄)
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","statusMessage":"⚠ CI ${CONCL}: $FNAME 생성됨 (gh-run:$RUN_ID)"}}
EOF

    type obs_event >/dev/null 2>&1 && obs_event "codex-automations" "ci-triage-generated" \
      '{"run_id":"'"$RUN_ID"'","conclusion":"'"$CONCL"'","file":"'"$FNAME"'","ts":"'$(date -Iseconds)'"}'
fi

exit 0
