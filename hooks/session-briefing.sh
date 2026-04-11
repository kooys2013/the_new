#!/bin/bash
# session-briefing.sh — 세션 시작 시 성장 메트릭 브리핑
# v2.5 Growth Engine #5: 능동적 제안

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
RULES_DIR="$CLAUDE_DIR/rules"

# 1. 교훈 수 카운트
LESSONS=0
if [ -f "$GLOBAL_MD" ]; then
  LESSONS=$(grep -c '^\- ' "$GLOBAL_MD" 2>/dev/null | tail -1 || echo 0)
fi

# 2. Rules 파일 수
RULES_COUNT=0
if [ -d "$RULES_DIR" ]; then
  RULES_COUNT=$(find "$RULES_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

# 3. 최근 세션에서 반복된 에러 (git log에서 fix: 커밋 카운트)
RECENT_FIXES=0
if command -v git &>/dev/null; then
  RECENT_FIXES=$(git log --oneline --since="7 days ago" --all 2>/dev/null | grep -ci 'fix' || echo 0)
fi

# 4. 성숙도 간이 계산
# 교훈 축적: 20개 이상이면 100%, 비례
LESSON_SCORE=$((LESSONS > 20 ? 100 : LESSONS * 5))
# 규칙 승격: 5개 이상이면 100%
RULES_SCORE=$((RULES_COUNT > 5 ? 100 : RULES_COUNT * 20))
# 평균
if [ $((LESSON_SCORE + RULES_SCORE)) -gt 0 ]; then
  MATURITY=$(( (LESSON_SCORE + RULES_SCORE) / 2 ))
else
  MATURITY=0
fi

# 출력
echo "┌─── Growth Briefing ───────────────────────┐"
echo "│ 교훈: ${LESSONS}개 | Rules: ${RULES_COUNT}개 | 최근 fix: ${RECENT_FIXES}건"
echo "│ 간이 성숙도: ${MATURITY}%"

# 5. 제안 생성
if [ "$RECENT_FIXES" -gt 5 ]; then
  echo "│ ⚠ fix 커밋 ${RECENT_FIXES}건 — 반복 에러 점검 권장"
fi
if [ "$RULES_COUNT" -lt 3 ]; then
  echo "│ 💡 rules/ 파일 ${RULES_COUNT}개 — 교훈 승격 검토 권장"
fi
if [ "$LESSONS" -gt 30 ]; then
  echo "│ 💡 교훈 ${LESSONS}개 — CLAUDE.md 정리 권장 (200줄 제한)"
fi

echo "└────────────────────────────────────────────┘"
