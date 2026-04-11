#!/bin/bash
# TypeScript 타입 체크 훅 (Claude Code PostToolUse 방식)
# stdin JSON에서 file_path 추출 → 프로젝트 로컬 tsc 우선 실행

INPUT=$(cat)

# stdin JSON에서 파일 경로 추출
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // ""' 2>/dev/null)

# .ts / .tsx 파일이 아니면 조기 종료
if [[ ! "$FILE_PATH" =~ \.(ts|tsx)$ ]]; then
  exit 0
fi

# 파일이 존재하지 않으면 종료
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 파일에서 프로젝트 루트 탐색 (tsconfig.json 위치)
DIR=$(dirname "$FILE_PATH")
PROJECT_ROOT=""
SEARCH_DIR="$DIR"
for i in $(seq 1 6); do
  if [ -f "$SEARCH_DIR/tsconfig.json" ]; then
    PROJECT_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

# tsc 경로: 로컬 node_modules 우선 → npx 폴백
TSC_BIN="$PROJECT_ROOT/node_modules/.bin/tsc"
if [ ! -f "$TSC_BIN" ]; then
  TSC_BIN=$(command -v tsc 2>/dev/null)
fi
if [ -z "$TSC_BIN" ]; then
  exit 0
fi

# 타입 체크 실행
cd "$PROJECT_ROOT" || exit 0
"$TSC_BIN" --noEmit 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "❌ TypeScript 타입 에러: $FILE_PATH"
fi

exit $EXIT_CODE
