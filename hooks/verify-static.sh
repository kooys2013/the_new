#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0
EXT="${FILE##*.}"
[ "$EXT" = "py" ] || exit 0
[ -f "$FILE" ] || exit 0
OUT=$(python3 -m py_compile "$FILE" 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ Python 컴파일 오류: $FILE" >&2
  echo "$OUT" >&2
  exit 2
fi
