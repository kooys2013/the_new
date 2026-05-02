#!/usr/bin/env bash
# trajectory-recorder — 사용자 결정: PostToolUse + Stop 2개만 등록
# v3 (2605010914)
set -euo pipefail
trap 'exit 0' ERR

[ "${TRAJECTORY_RECORDER_ENABLED:-1}" = "0" ] && exit 0

EVENT="${1:-unknown}"
INPUT=$(cat)
TS=$(date -u +%s.%3N 2>/dev/null || date -u +%s)
PROJECT=$(basename "$(pwd)")
SESSION=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null) || SESSION="default"

OUT_DIR="${HOME}/.claude/state/trajectory/${PROJECT}"
mkdir -p "$OUT_DIR" 2>/dev/null

DATE=$(date -u +%Y-%m-%d)
OUT_FILE="${OUT_DIR}/${DATE}.jsonl"

# 압축 저장 — file_text 등 큰 필드는 hash로 대체, prompt 200자 truncate
echo "$INPUT" | jq --arg ts "$TS" --arg ev "$EVENT" --arg sess "$SESSION" \
  '{ts: $ts, event: $ev, session: $sess, tool: .tool_name, file: .tool_input.file_path, summary: ((.tool_input.description // (.prompt // "")) | tostring | .[0:200])}' \
  >> "$OUT_FILE" 2>/dev/null || true

exit 0
