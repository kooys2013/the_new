#!/usr/bin/env bash
# devils-advocate-trigger.sh — UserPromptSubmit에서 결정 키워드 감지 + 10% 샘플링
# R3 완화: 10% 샘플링 게이트
# R1 준수: 트레이딩 진입 키워드 감지 시 SKIP

set -euo pipefail

# 10% 샘플링 게이트 (R3 완화)
if (( RANDOM % 10 != 0 )); then
  exit 0
fi

TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
PROMPT=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('prompt','')[:300])
" 2>/dev/null || echo "")

[[ -z "$PROMPT" ]] && exit 0

# R1 필터 — 트레이딩 진입 키워드 → SKIP
if echo "$PROMPT" | grep -qiE "진입.*신호|entry.*signal|매수.*시점|백테스트.*파라미터|lookback|스톱로스|손절|backtest_engine"; then
  exit 0
fi

# 결정 키워드 감지
if echo "$PROMPT" | grep -qiE "어떻게.*선택|어떤.*결정|어떻게.*해야|뭘.*골라|이게.*맞나|확실해|이게.*최선"; then
  echo '{"additionalContext": "💭 [devils-advocate] 결정 패턴 감지 — 반론 검토가 도움될 수 있습니다 (/devils-advocate)"}'
fi

exit 0
