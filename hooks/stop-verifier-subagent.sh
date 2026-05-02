#!/usr/bin/env bash
# stop-verifier-subagent — 사용자 결정: 기본 비활성, env 토글로 ON
# 활성화: export CLAUDE_STOP_VERIFIER_ENABLED=1
# v3 (2605010914)
set -euo pipefail
trap 'exit 0' ERR

# 사용자 결정: 기본 비활성
[ "${CLAUDE_STOP_VERIFIER_ENABLED:-0}" = "1" ] || exit 0

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

EDIT_COUNT=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null | grep -cE '"name":"(Edit|Write|MultiEdit)"' || echo 0)
[ "$EDIT_COUNT" -lt 1 ] && exit 0

# 자금 직결만 block, 일반은 verify-only
RISK=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null | grep -oE 'risk_gate|kill_switch|convex_sizer' | head -1 || echo "")

LOG_DIR="${HOME}/.claude/state/trajectory/$(basename $(pwd))"
mkdir -p "$LOG_DIR" 2>/dev/null

if [ -n "$RISK" ]; then
  cat <<JSON
{
  "decision": "block",
  "reason": "[stop-verifier] 자금 직결 모듈($RISK) 변경 감지. fresh subagent 검증 권장.\n\n실행: /verify L5 (예상 비용 ~3 USD)\n또는 사용자가 명시적 승인 시 진행."
}
JSON
  echo "[$(date -Iseconds)] BLOCK risk=$RISK edits=$EDIT_COUNT" >> "$LOG_DIR/stop-verifier.log"
  exit 0
fi

# 일반 변경 — fresh haiku 검증 옵션 (일일 cap 1 USD)
echo "[$(date -Iseconds)] PASS edits=$EDIT_COUNT" >> "$LOG_DIR/stop-verifier.log"
exit 0
