#!/bin/bash
# PostToolUse(Write) — .ts/.tsx/.js/.jsx 저장 시 OWASP 경량 스캔
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // ""' 2>/dev/null)

[[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]] && exit 0
[ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ] && exit 0

ISSUES=""
grep -n 'eval\s*(' "$FILE_PATH" 2>/dev/null && ISSUES="${ISSUES}\n⚠️ P0: eval() — XSS 위험"
grep -n 'dangerouslySetInnerHTML' "$FILE_PATH" 2>/dev/null && ISSUES="${ISSUES}\n⚠️ P1: dangerouslySetInnerHTML — 살균 확인"
grep -nE '(api[_-]?key|secret|password|token)\s*[:=]\s*["\x27][A-Za-z0-9]' "$FILE_PATH" 2>/dev/null && ISSUES="${ISSUES}\n🔴 P0: 하드코딩 시크릿"

if [ -n "$ISSUES" ]; then
  echo -e "❌ 보안 이슈: $FILE_PATH$ISSUES"
  exit 1
fi
exit 0
