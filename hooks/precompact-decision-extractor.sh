#!/usr/bin/env bash
# precompact-decision-extractor.sh — PreCompact 시 중요 결정 자동 추출 + index
# CTX 축 보강 (Gap 11): structured note 재조회 경로 확보
# coding-decision-journal `_cache/decisions/` 색인 자동 갱신
# 빠름: ≤200ms (파일 IO만)

set -euo pipefail

DECISIONS_DIR="$HOME/.claude/_cache/decisions"
INDEX_FILE="$DECISIONS_DIR/INDEX.md"

mkdir -p "$DECISIONS_DIR"

# 1. 30일 이내 ADR 파일 목록 → INDEX.md 갱신
{
  echo "# Decision Index — $(date '+%Y/%m/%d')"
  echo ""
  echo "## 최근 30일 결정"
  echo ""

  # ADR-* 파일 30일 이내
  if find "$DECISIONS_DIR" -name "ADR-*.md" -mtime -30 2>/dev/null | head -1 | grep -q .; then
    find "$DECISIONS_DIR" -name "ADR-*.md" -mtime -30 2>/dev/null | sort -r | while read f; do
      title=$(grep -m1 "^## ADR" "$f" 2>/dev/null | sed 's/^## //')
      mtime=$(stat -c %y "$f" 2>/dev/null || stat -f %Sm "$f" 2>/dev/null | head -c 10)
      [[ -n "$title" ]] && echo "- [$title]($(basename $f)) — $mtime"
    done
  else
    echo "_(최근 30일 결정 없음 — coding-decision-journal 미사용)_"
  fi

  echo ""
  echo "## 분기 결정 (Double-loop)"
  if find "$DECISIONS_DIR" -name "double-loop-*.md" 2>/dev/null | head -1 | grep -q .; then
    find "$DECISIONS_DIR" -name "double-loop-*.md" 2>/dev/null | sort -r | while read f; do
      echo "- $(basename $f)"
    done
  else
    echo "_(분기 회고 미실행 — double-loop-quarterly 권고)_"
  fi

  echo ""
  echo "## CTX 보존 권고"
  echo "- 컨텍스트 압축 직후 본 INDEX 재참조: \`Read $INDEX_FILE\`"
  echo "- 핵심 결정 누락 의심: \`grep -r \"R1\\|R5\\|R8\" $DECISIONS_DIR\`"
} > "$INDEX_FILE"

# 2. 컨텍스트 보존용 1줄 출력 (PreCompact 사용자 표시)
DECISIONS_30D=$(find "$DECISIONS_DIR" -name "ADR-*.md" -mtime -30 2>/dev/null | wc -l | tr -d ' ')
echo "[ctx-extractor] 결정 색인 갱신 — 30일 내 ADR ${DECISIONS_30D}건 → $INDEX_FILE"

# 3. obs 이벤트 (압축 시점 기록)
OBS_DIR="$HOME/.claude/_cache/obs"
mkdir -p "$OBS_DIR"
WEEK=$(date +%Y-%W)
echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"precompact-extracted\",\"adr_count\":$DECISIONS_30D}" \
  >> "$OBS_DIR/${WEEK}.jsonl"

exit 0
