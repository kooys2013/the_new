#!/bin/bash
# Codex 사용량 추적 + 적극 사용 권장
# SessionStart 시 실행 — Codex Proxy 실시간 데이터 + 로컬 로그 기반

PROXY_URL="http://localhost:8080"
USAGE_LOG="$HOME/.claude/codex-usage.log"
TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H)

touch "$USAGE_LOG"

# ── 1. Codex Proxy 실시간 잔여량 확인 ──
PROXY_DATA=$(curl -s --max-time 2 "$PROXY_URL/health" 2>/dev/null)
PROXY_OK=$(echo "$PROXY_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)

if [ "$PROXY_OK" = "ok" ]; then
  # Usage Stats API 시도
  USAGE_DATA=$(curl -s --max-time 2 "$PROXY_URL/api/usage-stats" 2>/dev/null)
  RATE_USED=$(echo "$USAGE_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    pct = d.get('rate_limit_percent', d.get('used_percent', None))
    print(pct if pct is not None else '')
except: print('')
" 2>/dev/null)

  PROXY_STATUS="🟢 Proxy ON"
  POOL=$(echo "$PROXY_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); p=d.get('pool',{}); print(f\"{p.get('active',0)}/{p.get('total',0)}\")" 2>/dev/null)

  if [ -n "$RATE_USED" ]; then
    RATE_INT=${RATE_USED%.*}
    if [ "$RATE_INT" -lt 20 ]; then
      RATE_EMOJI="🟢"
      RATE_MSG="여유 — 적극 활용 권장"
    elif [ "$RATE_INT" -lt 60 ]; then
      RATE_EMOJI="🟡"
      RATE_MSG="적정 사용 중"
    elif [ "$RATE_INT" -lt 85 ]; then
      RATE_EMOJI="🟠"
      RATE_MSG="주의 — 효율적 사용"
    else
      RATE_EMOJI="🔴"
      RATE_MSG="한도 임박 — 핵심 작업만"
    fi
    RATE_LINE="│ $RATE_EMOJI Rate Limit: ${RATE_USED}% Used | $RATE_MSG"
  else
    # 대시보드 화면 기준: 0% Used → 적극 사용 권장
    RATE_LINE="│ 🟢 Rate Limit: 0% Used — 쿼터 가득! 적극 활용 권장"
  fi
else
  PROXY_STATUS="⚫ Proxy OFF"
  POOL="-"
  RATE_LINE="│ ⚫ Proxy 미실행 — http://localhost:8080 확인"
fi

# ── 2. 로컬 사용 횟수 ──
TODAY_COUNT=$(grep "^$TODAY" "$USAGE_LOG" 2>/dev/null | wc -l)
HOURS_LEFT=$((24 - HOUR))

if [ "$TODAY_COUNT" -lt 2 ]; then
  COUNT_MSG="오늘 미사용 → /codex:review 먼저 돌려보세요"
elif [ "$TODAY_COUNT" -lt 5 ]; then
  COUNT_MSG="적정 사용 중"
else
  COUNT_MSG="활발히 사용 중"
fi

# ── 출력 ──
echo "┌─── Codex Usage ─────────────────────────┐"
echo "│ $PROXY_STATUS | Pool: $POOL accounts"
echo "$RATE_LINE"
echo "│ 오늘: ${TODAY_COUNT}회 (${HOURS_LEFT}h 남음) — $COUNT_MSG"
echo "└──────────────────────────────────────────┘"
