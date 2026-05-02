#!/usr/bin/env bash
# verify-suggest.sh — PostToolUse Edit/Write 후 LLM에게 "방금 변경됨 + /verify 매칭 권고" 컨텍스트 신호
#
# 핵심: hook이 /verify를 강제 invoke 하지 않는다. 대신 additionalContext로 LLM이
# 자연어 매칭 판단할 단서를 제공.
#
# 매칭 후 행동 규칙 (LLM이 따를):
#   - L0/L1/L2/L3/L4 (skip/훅확인/pytest/스크린샷/E2E) → 자동 진행
#   - L5 (서브에이전트 claude -p, 0.05~5 USD) → 사용자 컨센트 후 진입
#
# 가드: rate limit 24h/파일 + 5줄 미만 skip + 비코드 파일 skip
set -e

INPUT=$(cat 2>/dev/null || echo "{}")

# tool_input.file_path 파싱 (Python 1줄)
FILE=$(echo "$INPUT" | python -c "import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('tool_input',{}).get('file_path',''))
except: pass" 2>/dev/null || echo "")

[ -z "$FILE" ] && exit 0

# 비코드 파일 skip
case "$FILE" in
  *.md|*.json|*.txt|*.yaml|*.yml|*.toml|*.lock|*.log|*.csv) exit 0 ;;
esac

# rate limit (파일별 24h)
HASH=$(echo -n "$FILE" | sha256sum 2>/dev/null | cut -c1-8)
[ -z "$HASH" ] && exit 0
mkdir -p ~/.claude/_cache/verify-suggest 2>/dev/null
LOCK=~/.claude/_cache/verify-suggest/${HASH}.last
if [ -f "$LOCK" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
  [ "$AGE" -lt 86400 ] && exit 0
fi
touch "$LOCK"

# 변경 줄 수 확인 (5줄 미만 skip)
LINES=$(git diff --numstat HEAD -- "$FILE" 2>/dev/null | awk 'NR==1 {print $1+$2}')
[ -z "$LINES" ] && LINES=0
[ "$LINES" -lt 5 ] && exit 0

# 파일 경로로 레벨/힌트 추정
LEVEL=L1
HINT="훅 결과 확인"
case "$FILE" in
  *.tsx|*.css|*frontend/src/components/*) LEVEL=L3; HINT="스크린샷 1장 (Playwright)" ;;
  *backend/engine/*.py)                   LEVEL=L2; HINT="pytest 타겟 테스트" ;;
  *backend/api/routes/*.py)               LEVEL=L2; HINT="pytest + curl 헬스체크" ;;
  *backend/*.py)                          LEVEL=L2; HINT="pytest 타겟" ;;
  *frontend/src/*.ts|*frontend/src/*.tsx) LEVEL=L1; HINT="훅 + tsc --noEmit" ;;
  *.py)                                   LEVEL=L1; HINT="py_compile + 훅" ;;
esac

# additionalContext 주입 — LLM에게 "이런 변경이 있었음 + 자연어 매칭 시 /verify"라는 정보만 제공
# L0~L4 자동, L5만 사용자 컨센트 — 이 hint도 함께 명시
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "[verify-suggest] 방금 ${FILE} ${LINES}줄 변경됨. 사용자가 '됐나/확인/수정/고쳤어' 류 발화 시 /verify 자가검증 매칭 (추정 ${LEVEL} — ${HINT}). 행동 규칙: L0~L4는 자동 진행 / L5(서브에이전트, 0.05~5 USD)만 사용자 컨센트 후 진입. hook이 강제 invoke 하는 게 아니라 LLM이 자율 판단."
  }
}
EOF
