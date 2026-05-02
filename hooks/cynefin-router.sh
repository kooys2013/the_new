#!/usr/bin/env bash
# cynefin-router.sh — UserPromptSubmit에서 Cynefin 도메인 자동 분류 (10% 샘플링)
# R3 완화: 10% 샘플링 게이트 적용 (cynefin/devils/prompt-refiner 충돌 방지)
# 출력: additionalContext JSON으로 도메인 힌트 제공

set -euo pipefail

# 10% 샘플링 게이트 (R3 완화)
if (( RANDOM % 10 != 0 )); then
  exit 0
fi

TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
PROMPT=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('prompt','')[:200])
" 2>/dev/null || echo "")

[[ -z "$PROMPT" ]] && exit 0

# 키워드 기반 도메인 분류
DOMAIN="COMPLICATED"  # 기본값

# CHAOTIC 신호 (즉각 행동 필요)
if echo "$PROMPT" | grep -qiE "긴급|당장|즉시|crisis|emergency|crashed|다운됐|서버|에러 폭발"; then
  DOMAIN="CHAOTIC"
fi

# SIMPLE 신호 (정답 명확)
if echo "$PROMPT" | grep -qiE "어떻게.*하나요|사용법|명령어|문법|syntax"; then
  DOMAIN="SIMPLE"
fi

# COMPLEX 신호 (탐색/창발)
if echo "$PROMPT" | grep -qiE "전략|방향|어떻게.*접근|새로운.*방법|패러다임|진짜 문제|재정의|처음부터"; then
  DOMAIN="COMPLEX"
fi

# 도메인별 힌트
case "$DOMAIN" in
  SIMPLE)
    HINT="SIMPLE 도메인 — 체크리스트/문서 참조로 충분"
    ;;
  COMPLICATED)
    HINT="COMPLICATED 도메인 — 전문가 분석 + SDG 6요소 검토"
    ;;
  COMPLEX)
    HINT="COMPLEX 도메인 — 탐색적 접근 권장, unbounded-engine 고려"
    ;;
  CHAOTIC)
    HINT="CHAOTIC 도메인 — 즉각 행동 우선, 분석은 나중에"
    ;;
esac

echo "{\"additionalContext\": \"🌐 [cynefin-router] $HINT\"}"
exit 0
