#!/bin/bash
# Codex 상태 — 공식 플러그인(openai/codex-plugin-cc) 기반
# SessionStart 시 실행

COMPANION="$HOME/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs"

if [ ! -f "$COMPANION" ]; then
  echo "┌─── Codex Usage ─────────────────────────┐"
  echo "│ ⚫ Codex 플러그인 미설치                  │"
  echo "│ → /plugin install codex@openai-codex    │"
  echo "└──────────────────────────────────────────┘"
  exit 0
fi

# companion setup 실행 (JSON)
SETUP=$(node "$COMPANION" setup --json 2>/dev/null)
if [ -z "$SETUP" ]; then
  echo "┌─── Codex Usage ─────────────────────────┐"
  echo "│ ⚫ Codex companion 응답 없음               │"
  echo "└──────────────────────────────────────────┘"
  exit 0
fi

CODEX_AVAILABLE=$(echo "$SETUP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('codex',{}).get('available',False))" 2>/dev/null)
LOGGED_IN=$(echo "$SETUP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('auth',{}).get('loggedIn',False))" 2>/dev/null)
CODEX_VER=$(echo "$SETUP" | python3 -c "import json,sys; d=json.load(sys.stdin); det=d.get('codex',{}).get('detail',''); print(det.split(';')[0].replace('codex-cli ','v') if det else '-')" 2>/dev/null)

if [ "$CODEX_AVAILABLE" != "True" ]; then
  STATUS_LINE="⚫ Codex 미설치 — npm install -g @openai/codex"
elif [ "$LOGGED_IN" != "True" ]; then
  STATUS_LINE="🟡 ${CODEX_VER} — 미인증 → !codex login"
else
  STATUS_LINE="🟢 ${CODEX_VER} — Ready"
fi

# 로컬 사용 로그 (호환용)
USAGE_LOG="$HOME/.claude/codex-usage.log"
TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H)
touch "$USAGE_LOG" 2>/dev/null || true
TODAY_COUNT=$(grep "^$TODAY" "$USAGE_LOG" 2>/dev/null | wc -l | tr -d ' ')
HOURS_LEFT=$((24 - HOUR))

if [ "$TODAY_COUNT" -eq 0 ]; then
  COUNT_MSG="오늘 미사용 → /codex:review 먼저 돌려보세요"
elif [ "$TODAY_COUNT" -lt 5 ]; then
  COUNT_MSG="오늘 ${TODAY_COUNT}회 사용"
else
  COUNT_MSG="오늘 ${TODAY_COUNT}회 — 활발히 사용 중"
fi

echo "┌─── Codex (공식 플러그인) ────────────────┐"
echo "│ $STATUS_LINE"
echo "│ ${COUNT_MSG} (${HOURS_LEFT}h 남음)"
echo "└──────────────────────────────────────────┘"
