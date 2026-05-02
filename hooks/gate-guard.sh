#!/bin/bash
# PreToolUse(Edit|Write) — GateGuard v1.0
# ECC GateGuard 패턴: "Enforcement via infrastructure, not instruction"
# affaan-m/everything-claude-code 에서 추출 적용 (26/04/17)

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

[ -z "$FILE" ] && exit 0

# 1. 글로벌 하네스 보호 파일 감지
CRITICAL_PATTERNS=(
  '\.claude[/\\]settings\.json'
  '\.claude[/\\]CLAUDE\.md'
  '\.claude[/\\]hooks[/\\].*\.sh'
  '\.claude[/\\]rules[/\\].*\.md'
  '\.mcp\.json$'
)

for p in "${CRITICAL_PATTERNS[@]}"; do
  if echo "$FILE" | grep -qiE "$p"; then
    echo "GateGuard [GLOBAL-CONFIG]: $FILE"
    echo "  -> 전역 하네스 파일. Read 확인 + accumulated-lessons 위반 없음 확인 필수"
    # warn only (D+14 후 block 승격 검토)
    exit 0
  fi
done

# 2. Write 도구에서 기존 파일 덮어쓰기 감지 (ALWAYS: Write 전 Read 규칙 강제)
if [ "$TOOL" = "Write" ] && [ -f "$FILE" ]; then
  echo "GateGuard [OVERWRITE]: 기존 파일 덮어쓰기 감지 — $(basename "$FILE")"
  echo "  -> ALWAYS: Write 전 Read 확인 (accumulated-lessons SCP-5)"
  exit 0
fi

exit 0
