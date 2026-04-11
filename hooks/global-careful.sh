#!/bin/bash
# PreToolUse(Bash) — 파괴적 명령 전역 차단
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

PATTERNS=('rm -rf /' 'rm -rf ~' 'DROP TABLE' 'DROP DATABASE' 'git push.*--force' 'git reset --hard' 'kubectl delete' 'mkfs\.' 'dd if=')

for p in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$p"; then
    echo "🔴 BLOCKED: 파괴적 명령 감지 — '$p'"
    exit 2
  fi
done
exit 0
