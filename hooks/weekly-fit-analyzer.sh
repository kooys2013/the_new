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

# L3: rules paths "**/*" 카운트 모니터링 (7개 초과 시 경고)
RULES_DIR="$HOME/.claude/rules"
WILDCARD_COUNT=$(grep -rl '"**/*"' "$RULES_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [ "$WILDCARD_COUNT" -gt 6 ]; then
  {
    echo ""
    echo "## ⚠ Context-Bloat 경고"
    echo "- \`paths: \"**/*\"\` 파일 수: ${WILDCARD_COUNT}개 (기준 ≤6)"
    echo "- 초과 파일 확인: \`grep -rl '\"**/*\"' ~/.claude/rules/ | xargs head -3\`"
    echo "- Core DNA 6종 외 파일은 \`__on_demand_only__\`로 재할당 필요"
  } >> "$REPORT"
fi

# pending 플래그
cp "$REPORT" "$PENDING"

# Slack 알림 (hooks/slack-notify.sh 존재 시)
if [ -x "$HOME/.claude/hooks/slack-notify.sh" ]; then
  "$HOME/.claude/hooks/slack-notify.sh" "주간 FIT 제안 준비됨: $REPORT" 2>/dev/null || true
fi

echo "리포트 생성: $REPORT"

# === Anthropic 블로그 주간 스캔 ===
# origin: claude.com/blog integration | merged: 26/04/17
BLOG_CACHE="$HOME/.claude/_cache/anthropic-blog-seen.txt"
touch "$BLOG_CACHE"

BLOG_NEW=0
BLOG_TITLES=""

# claude.com/blog sitemap에서 최근 7일 글 감지 (curl 실패 시 경고만)
if command -v curl >/dev/null 2>&1; then
  BLOG_RAW=$(curl -sL --max-time 10 "https://claude.com/blog" 2>/dev/null | \
    grep -oE 'href="/blog/[^"]+"|<h[23][^>]*>[^<]{10,80}</h[23]>' | \
    head -30 || true)
  if [ -n "$BLOG_RAW" ]; then
    while IFS= read -r LINE; do
      SLUG=$(echo "$LINE" | grep -oE '/blog/[^"]+' | head -1)
      [ -z "$SLUG" ] && continue
      if ! grep -qF "$SLUG" "$BLOG_CACHE" 2>/dev/null; then
        echo "$SLUG" >> "$BLOG_CACHE"
        BLOG_NEW=$((BLOG_NEW + 1))
        BLOG_TITLES="${BLOG_TITLES}\n  - https://claude.com${SLUG}"
      fi
    done <<< "$BLOG_RAW"
  fi
fi

if [ "$BLOG_NEW" -gt 0 ]; then
  {
    echo ""
    echo "## 📡 Anthropic 블로그 신규 ${BLOG_NEW}건 (최근 감지)"
    echo -e "$BLOG_TITLES"
    echo "→ unbounded-engine Phase 2 또는 research-pipeline Phase 8에서 참조 권장"
  } >> "$REPORT"
  cp "$REPORT" "$PENDING"
  [ -x "$HOME/.claude/hooks/slack-notify.sh" ] && \
    "$HOME/.claude/hooks/slack-notify.sh" "📡 Anthropic 블로그 신규 ${BLOG_NEW}건 감지" 2>/dev/null || true
fi
