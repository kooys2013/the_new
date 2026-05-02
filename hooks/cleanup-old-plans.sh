#!/bin/bash
# cleanup-old-plans.sh — plans/ 폴더 30일+ 미수정 파일을 _archive/ 로 이동
# SessionStart에서 1일 1회 게이트 실행 (async)
# S4: context-bloat remediation 26/04/28

set -euo pipefail

PLANS_DIR="$HOME/.claude/plans"
ARCHIVE_DIR="$HOME/.claude/plans/_archive"
GATE_FILE="$HOME/.claude/_cache/cleanup-plans-gate.txt"
TODAY=$(date +%Y%m%d)

# 1일 1회 게이트
if [ -f "$GATE_FILE" ] && [ "$(cat "$GATE_FILE" 2>/dev/null)" = "$TODAY" ]; then
  exit 0
fi
echo "$TODAY" > "$GATE_FILE"

# _archive 폴더 보장
mkdir -p "$ARCHIVE_DIR"

# 30일+ 미수정 plans/*.md (서브폴더 제외)
ARCHIVED=0
while IFS= read -r f; do
  base=$(basename "$f")
  # 이미 _archive 내부는 스킵
  [[ "$f" == */_archive/* ]] && continue
  # 파일명 앞에 날짜 스탬프 붙여 이동
  dest="$ARCHIVE_DIR/${TODAY}_${base}"
  mv "$f" "$dest"
  ARCHIVED=$((ARCHIVED + 1))
done < <(find "$PLANS_DIR" -maxdepth 1 -name "*.md" -type f -mtime +30 2>/dev/null)

if [ "$ARCHIVED" -gt 0 ]; then
  echo "cleanup-old-plans: ${ARCHIVED}개 plan 아카이브 → $ARCHIVE_DIR"
fi
