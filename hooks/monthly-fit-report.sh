#!/bin/bash
# monthly-fit-report.sh — 월간 심층 FIT (매월 1일 03:00)
# 30일 TIMELINE 분석 + archive/승격 후보 + retrospective-engine 호출

set -uo pipefail
VIBE_DIR="$HOME/vibe-sunsang"
TIMELINE="$VIBE_DIR/growth-log/TIMELINE.md"
REPORT_DIR="$HOME/_report"
mkdir -p "$REPORT_DIR"

YM=$(date +%y%m)
REPORT="$REPORT_DIR/${YM}_monthly_fit.md"

{
  echo "# $YM 월간 FIT 심층 리포트"
  echo "생성: $(date)"
  echo ""
  echo "## 30일 TIMELINE 요약"
  [ -f "$TIMELINE" ] && tail -n 500 "$TIMELINE" | grep -E 'L[0-9]' | tail -n 100 || echo "(TIMELINE 없음)"
  echo ""
  echo "## Archive 후보 (6개월 위반 0회 훅)"
  find "$HOME/.claude/hooks" -name "*.sh" -mtime +180 2>/dev/null | head -10
  echo ""
  echo "## 승격 후보 (3회+ 축적 교훈)"
  if [ -f "$HOME/.claude/rules/accumulated-lessons.md" ]; then
    grep -E '^\- (ALWAYS|NEVER)' "$HOME/.claude/rules/accumulated-lessons.md" 2>/dev/null | \
      sort | uniq -c | sort -rn | awk '$1>=3' | head -10
  fi
  echo ""
  echo "## 다음 단계"
  echo "- retrospective-engine Phase 4.5 졸업 판정 실행"
  echo "- 효과 있는 규칙 → hooks/ 승격"
  echo "- 효과 없는 규칙 → archive"
} > "$REPORT"

echo "월간 리포트: $REPORT"

[ -x "$HOME/.claude/hooks/slack-notify.sh" ] && \
  "$HOME/.claude/hooks/slack-notify.sh" "월간 FIT 리포트: $REPORT" 2>/dev/null || true
