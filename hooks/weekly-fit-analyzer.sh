#!/bin/bash
# weekly-fit-analyzer.sh — 주간 FIT 분석 (일요일 22:00)
# vibe-sunsang TIMELINE 7일 diff → 최약 축 식별 → 3옵션 리포트 생성

set -uo pipefail
VIBE_DIR="$HOME/vibe-sunsang"
TIMELINE="$VIBE_DIR/growth-log/TIMELINE.md"
CACHE_DIR="$HOME/.claude/_cache"
PENDING="$CACHE_DIR/weekly-fit-pending.md"
mkdir -p "$CACHE_DIR"

[ ! -f "$TIMELINE" ] && { echo "TIMELINE.md 없음 — vibe-sunsang 관찰 필요"; exit 0; }

# 최근 7일치 L 값 추출 (매우 단순한 근사)
# TIMELINE 포맷 예: "26/04/17 FAIL L2.8" 형태 가정
WEEK_DATA=$(tail -n 200 "$TIMELINE" 2>/dev/null | tail -n 50)

# 축별 평균 L 산출 (FAIL/VERIFY/DECOMP/ORCH/CTX/META)
TODAY=$(date +%y%m%d)
REPORT="$CACHE_DIR/weekly-fit-$TODAY.md"

{
  echo "# 📊 주간 FIT 분석 — $(date +%y/%m/%d)"
  echo ""
  echo "## 최근 7일 축별 신호"
  for AXIS in DECOMP VERIFY ORCH FAIL CTX META; do
    COUNT=$(echo "$WEEK_DATA" | grep -c "$AXIS" || echo 0)
    LAST_L=$(echo "$WEEK_DATA" | grep "$AXIS" | tail -1 | grep -oE 'L[0-9]+\.?[0-9]*' | head -1)
    echo "- $AXIS: 언급 ${COUNT}회, 최근 ${LAST_L:-N/A}"
  done
  echo ""
  echo "## 제안"
  echo "A. 최약 축의 트리거를 warn → block 승격 (rules/auto-triggers.md)"
  echo "B. 해당 축 관련 훅 신설 (hooks/)"
  echo "C. 아무것도 안 함 (다음 주 재평가)"
  echo ""
  echo "▶ 적용: \`bash ~/.claude/hooks/apply-weekly-fit.sh <A|B|C>\`"
} > "$REPORT"

# pending 플래그
cp "$REPORT" "$PENDING"

# Slack 알림 (hooks/slack-notify.sh 존재 시)
if [ -x "$HOME/.claude/hooks/slack-notify.sh" ]; then
  "$HOME/.claude/hooks/slack-notify.sh" "주간 FIT 제안 준비됨: $REPORT" 2>/dev/null || true
fi

echo "리포트 생성: $REPORT"
