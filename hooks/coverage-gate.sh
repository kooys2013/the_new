#!/usr/bin/env bash
# coverage-gate — PostToolUse Edit|Write 백엔드 Python 분기 커버리지 게이트
# v3 (2605010914): backtest_engine.py 자동 skip
set -euo pipefail
trap 'exit 0' ERR

# 비활성 토글
[ "${COVERAGE_GATE_DISABLED:-0}" = "1" ] && exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -z "$FILE" ] && exit 0

# 백엔드 Python만
[[ "$FILE" =~ \.py$ ]] || exit 0
[[ "$FILE" =~ /backend/|/engine/|/api/|/strategy/|/scorer/ ]] || exit 0

# 사용자 결정: backtest_engine.py 제외
SKIP_PATTERN="${COVERAGE_GATE_SKIP_PATTERN:-backtest_engine\.py$}"
[[ "$FILE" =~ $SKIP_PATTERN ]] && exit 0

# 프로젝트 루트
PROJ_ROOT=$(cd "$(dirname "$FILE")" && git rev-parse --show-toplevel 2>/dev/null) || exit 0
COV_FILE="$PROJ_ROOT/.coverage"
[ -f "$COV_FILE" ] || exit 0

# 위험도 분류 (간이)
TARGET="${COVERAGE_BRANCH_TARGET_C:-80}"
[[ "$FILE" =~ risk_gate|kill_switch|convex_sizer|order_ ]] && TARGET="${COVERAGE_BRANCH_TARGET_A:-95}"

# coverage report 분석
cd "$PROJ_ROOT"
if ! python -m coverage report --fail-under="$TARGET" --skip-covered > /dev/null 2>&1; then
  REPORT=$(python -m coverage report 2>&1 | tail -10)
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[coverage-gate] 분기 ${TARGET}% 미달 (대상: $FILE)\n${REPORT}\n→ /verify 진입 시 누락 분기 보강 권고. backtest_engine.py는 자동 skip됨."
  }
}
EOF
fi

exit 0
