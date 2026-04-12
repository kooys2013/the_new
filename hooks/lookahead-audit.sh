#!/usr/bin/env bash
# lookahead-audit.sh — PostToolUse 훅
# go-v2/backend/engine/*.py 수정 시 자동으로 정적 lookahead audit 실행
#
# 탈출 코드:
#   0 = PASS 또는 해당 없음
#   1 = 탐지 건수 > 0 (Claude에게 차단 메시지 전달)

set -euo pipefail

# CLAUDE_TOOL_INPUT_FILE_PATH 환경변수 (PostToolUse에서 수정된 파일 경로)
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# 파일 경로가 go-v2/backend/engine/*.py 패턴인지 확인
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if [[ ! "$FILE_PATH" =~ go-v2[/\\]backend[/\\]engine[/\\][^/\\]+\.py$ ]]; then
  exit 0
fi

# 엔진 디렉토리 추출
ENGINE_DIR=$(dirname "$FILE_PATH")

# Python 경로 확인
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
if [[ -z "$PYTHON" ]]; then
  echo "WARNING: Python not found, lookahead audit skipped" >&2
  exit 0
fi

# lookahead_audit.py 존재 확인
AUDIT_SCRIPT="$ENGINE_DIR/lookahead_audit.py"
if [[ ! -f "$AUDIT_SCRIPT" ]]; then
  exit 0
fi

# 감사 실행
cd "$ENGINE_DIR"
RESULT=$("$PYTHON" lookahead_audit.py . 2>&1) || AUDIT_EXIT=$?
AUDIT_EXIT="${AUDIT_EXIT:-0}"

if [[ "$AUDIT_EXIT" -ne 0 ]]; then
  echo ""
  echo "⚠️  LOOKAHEAD AUDIT FAIL — 도리님 원칙 §1 위반 감지"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$RESULT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "수정 후 재실행하여 0건 확인 필요"
  exit 1
fi

exit 0
