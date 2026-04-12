#!/bin/bash
# PostToolUse — Codex 호출 시 사용 로그 기록
# matcher: Bash (codex 명령 감지)

INPUT=$(cat)
USAGE_LOG="$HOME/.claude/codex-usage.log"

# codex 관련 호출인지 확인
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' 2>/dev/null | head -1)

if echo "$COMMAND" | grep -qi "codex"; then
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  MODE="unknown"

  if echo "$COMMAND" | grep -qi "review"; then
    MODE="review"
  elif echo "$COMMAND" | grep -qi "adversarial"; then
    MODE="adversarial-review"
  elif echo "$COMMAND" | grep -qi "rescue"; then
    MODE="rescue"
  elif echo "$COMMAND" | grep -qi "status"; then
    MODE="status"
  fi

  echo "$TIMESTAMP $MODE" >> "$USAGE_LOG"
fi

exit 0
