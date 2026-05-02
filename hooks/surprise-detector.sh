#!/usr/bin/env bash
# surprise-detector.sh — PostToolUse(Edit|Write) 예상치 못한 변경 감지
# 변경 파일이 plan.md 범위에 없거나 변경 줄 수가 예상보다 많을 때 경고
# coding-confidence-tracker + plan-mode-router 연동

set -euo pipefail

TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
inp = d.get('tool_input',{})
print(inp.get('file_path','') or inp.get('path',''))
" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" ]] && exit 0

# 최근 plan.md 확인 (24시간 이내)
PLANS_DIR="$HOME/.claude/_cache/plans"
RECENT_PLAN=$(find "$PLANS_DIR" -name "*-plan.md" -mmin -1440 2>/dev/null | sort -t- -k1 -r | head -1)

# plan이 없으면 skip
[[ -z "$RECENT_PLAN" ]] && exit 0

# 파일이 plan의 범위에 포함되는지 확인
FILE_BASENAME=$(basename "$FILE_PATH")
if ! grep -q "$FILE_BASENAME" "$RECENT_PLAN" 2>/dev/null; then
  # plan에 없는 파일 변경 → 경고
  echo "{\"additionalContext\": \"⚠️ [surprise-detector] '$FILE_BASENAME'은 현재 plan.md 범위 밖의 파일입니다. plan-mode-router Plan을 먼저 확인하세요.\"}"

  # obs 이벤트
  OBS_DIR="$HOME/.claude/_cache/obs"
  mkdir -p "$OBS_DIR"
  WEEK=$(date +%Y-%W)
  echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"out-of-plan-edit\",\"file\":\"$FILE_BASENAME\"}" \
    >> "$OBS_DIR/${WEEK}.jsonl"
fi

exit 0
