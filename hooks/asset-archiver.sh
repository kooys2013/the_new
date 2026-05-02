#!/usr/bin/env bash
# asset-archiver.sh — 주간 자산 라이프사이클 전이 제안
# 30d WARN → 60d DORMANT → 150d CANDIDATE-ARCHIVE
# 200 자산 임계 알림 (R1 자산 비대화 방지)
# SessionStart 또는 cron(매주 월요일 09:00)에서 호출

set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
HOOKS_DIR="$HOME/.claude/hooks"
RULES_DIR="$HOME/.claude/rules"
COUNTERS="$HOME/.claude/_state/use-counters.jsonl"
CACHE_DIR="$HOME/.claude/_cache/harness"
mkdir -p "$CACHE_DIR"

REPORT="$CACHE_DIR/asset-archiver-$(date +%Y%m%d).md"
NOW_EPOCH=$(date +%s)
WARN_DAYS=30
DORMANT_DAYS=60
CANDIDATE_DAYS=150

# 자산 총수 카운트
TOTAL_SKILLS=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
TOTAL_HOOKS=$(find "$HOOKS_DIR" -name "*.sh" 2>/dev/null | wc -l)
TOTAL_RULES=$(find "$RULES_DIR" -name "*.md" 2>/dev/null | wc -l)
TOTAL=$((TOTAL_SKILLS + TOTAL_HOOKS + TOTAL_RULES))

{
echo "# Asset Archiver Report — $(date '+%Y/%m/%d')"
echo ""
echo "## 자산 현황"
echo "- Skills: $TOTAL_SKILLS | Hooks: $TOTAL_HOOKS | Rules: $TOTAL_RULES"
echo "- **총 자산: $TOTAL**"
echo ""

# 임계 알림
if [[ $TOTAL -ge 200 ]]; then
  echo "🚨 **CRITICAL: 자산 200 임계 초과! 즉시 정리 필요**"
elif [[ $TOTAL -ge 180 ]]; then
  echo "⚠️  **WARN: 자산 180+ — archive 검토 권장**"
fi

echo ""
echo "## 라이프사이클 후보"
echo ""

# use-counter에서 최근 60일 참조된 스킬 목록
RECENT_SKILLS=()
if [[ -f "$COUNTERS" ]]; then
  CUTOFF=$(date -d "60 days ago" +%s 2>/dev/null || date -v-60d +%s 2>/dev/null || echo "0")
  while IFS= read -r line; do
    skill=$(echo "$line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('skill',''))" 2>/dev/null || echo "")
    ts=$(echo "$line" | python3 -c "import sys,json,datetime; d=json.loads(sys.stdin.read()); ts=d.get('ts',''); print(int(datetime.datetime.fromisoformat(ts.replace('Z','+00:00')).timestamp()) if ts else 0)" 2>/dev/null || echo "0")
    [[ $ts -gt $CUTOFF ]] && RECENT_SKILLS+=("$skill")
  done < "$COUNTERS"
fi

# Skills 전이 분석
CANDIDATE_COUNT=0
DORMANT_COUNT=0
while IFS= read -r skill_file; do
  dir=$(dirname "$skill_file")
  skill_name=$(basename "$dir")

  # 마지막 수정 시간
  MOD_EPOCH=$(stat -c %Y "$skill_file" 2>/dev/null || stat -f %m "$skill_file" 2>/dev/null || echo "0")
  DAYS_OLD=$(( (NOW_EPOCH - MOD_EPOCH) / 86400 ))

  # use-counter에서 참조 여부
  IN_RECENT=0
  for rs in "${RECENT_SKILLS[@]}"; do
    [[ "$rs" == "$skill_name" ]] && IN_RECENT=1 && break
  done

  # dormant 마커 체크
  HAS_DORMANT=$(grep -l "<!-- dormant:" "$skill_file" 2>/dev/null | wc -l || echo "0")
  HAS_CANDIDATE=$(grep -l "<!-- candidate:" "$skill_file" 2>/dev/null | wc -l || echo "0")

  if [[ $IN_RECENT -eq 0 && $DAYS_OLD -ge $CANDIDATE_DAYS && $HAS_CANDIDATE -eq 0 ]]; then
    echo "- **CANDIDATE-ARCHIVE**: $skill_name (${DAYS_OLD}일 미참조)"
    ((CANDIDATE_COUNT++))
  elif [[ $IN_RECENT -eq 0 && $DAYS_OLD -ge $DORMANT_DAYS && $HAS_DORMANT -eq 0 ]]; then
    echo "- DORMANT: $skill_name (${DAYS_OLD}일 미참조)"
    ((DORMANT_COUNT++))
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null)

echo ""
echo "## 요약"
echo "- CANDIDATE-ARCHIVE 후보: $CANDIDATE_COUNT 건"
echo "- DORMANT 후보: $DORMANT_COUNT 건"
echo ""
echo "## 적용 방법"
echo "\`\`\`"
echo "apply-daily-fit.sh D ~/.claude/skills/<name>/SKILL.md   # DORMANT 강등"
echo "apply-daily-fit.sh P ~/.claude/skills/<name>/SKILL.md   # ARCHIVE 승격"
echo "\`\`\`"
} > "$REPORT"

# 임계 초과 시 obs 이벤트
OBS_DIR="$HOME/.claude/_cache/obs"
mkdir -p "$OBS_DIR"
WEEK=$(date +%Y-%W)
if [[ $TOTAL -ge 200 ]]; then
  echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"asset-bloat-critical\",\"total\":$TOTAL}" \
    >> "$OBS_DIR/${WEEK}.jsonl"
elif [[ $TOTAL -ge 180 ]]; then
  echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"asset-bloat-warn\",\"total\":$TOTAL}" \
    >> "$OBS_DIR/${WEEK}.jsonl"
fi

# 출력: additionalContext용 briefing
if [[ $CANDIDATE_COUNT -gt 0 || $TOTAL -ge 180 ]]; then
  echo "🗄 [asset-archiver] 총 $TOTAL 자산 | CANDIDATE: ${CANDIDATE_COUNT}건 | DORMANT: ${DORMANT_COUNT}건 → $REPORT"
fi

exit 0
