#!/usr/bin/env bash
# use-counter.sh — PostToolUse 스킬 호출 카운터
# sessions.jsonl에 스킬 이름 기록 → auto-mutation-pipeline / asset-lifecycle 분석 소스
# 빠름: ≤20ms (파일 append I/O만)

set -euo pipefail

# 스킬 호출 여부 감지 (stdin JSON에서 tool_name 추출)
TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
TOOL_NAME=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")

# Skill 도구 호출만 기록
if [[ "$TOOL_NAME" != "Skill" ]]; then
  exit 0
fi

SKILL_NAME=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
inp = d.get('tool_input',{})
print(inp.get('skill','') or inp.get('name',''))
" 2>/dev/null || echo "")

if [[ -z "$SKILL_NAME" ]]; then
  exit 0
fi

STATE_DIR="$HOME/.claude/_state"
mkdir -p "$STATE_DIR"
COUNTER_FILE="$STATE_DIR/use-counters.jsonl"

echo "{\"ts\":\"$(date -Iseconds)\",\"skill\":\"$SKILL_NAME\",\"session\":\"${CLAUDE_SESSION_ID:-unknown}\"}" \
  >> "$COUNTER_FILE"

exit 0
