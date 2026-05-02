#!/bin/bash
# stale-drawer-detector.sh — wing_knowledge drawer 중 last_compiled가 오래된 것 감지
# GBrain의 "compiled_truth older than latest timeline" 패턴 이식
# 실행: 주간 (crontab or Windows Task Scheduler) 또는 SessionStart 시 1회 (async)
# origin: garrytan/gbrain@stale-detection | merged: 26/04/18

set -uo pipefail

PALACE="${HOME}/.mempalace"
CACHE_DIR="${HOME}/.claude/_cache"
REPORT="${CACHE_DIR}/stale-drawers-$(date +%y%m%d).md"
STALE_DAYS="${STALE_DAYS:-90}"  # 기본 90일

mkdir -p "$CACHE_DIR"

# wing_knowledge 디렉토리 탐색 (MemPalace chroma + sqlite 구조)
# SQLite 기반이므로 .md 파일 대신 knowledge_graph.sqlite3 내 content 검색 시도
# Fallback: _cache 내 이전 내보낸 md 파일 검색

STALE_COUNT=0
STALE_LIST=""

# MemPalace SQLite에서 wing_knowledge 항목의 last_compiled 추출
SQLITE_DB="${PALACE}/knowledge_graph.sqlite3"

if [ -f "$SQLITE_DB" ]; then
  # SQLite에서 wing_knowledge drawer 조회 (content에서 last_compiled 파싱)
  while IFS='|' read -r drawer_id content_snippet; do
    LAST_COMPILED=$(echo "$content_snippet" | grep -oE "last_compiled:[[:space:]]*[0-9]{2}/[0-9]{2}/[0-9]{2}" | head -1 | grep -oE "[0-9]{2}/[0-9]{2}/[0-9]{2}")
    [ -z "$LAST_COMPILED" ] && continue

    # 날짜 계산
    YY="${LAST_COMPILED:0:2}"
    MM="${LAST_COMPILED:3:2}"
    DD="${LAST_COMPILED:6:2}"
    COMPILED_EPOCH=$(date -d "20${YY}-${MM}-${DD}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "20${YY}-${MM}-${DD}" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    AGE_DAYS=$(( (NOW_EPOCH - COMPILED_EPOCH) / 86400 ))

    if [ "$AGE_DAYS" -gt "$STALE_DAYS" ]; then
      STALE_COUNT=$((STALE_COUNT + 1))
      TITLE=$(echo "$content_snippet" | grep -oE "title:[^\\n]+" | head -1 | sed 's/title://;s/^[ \\t]*//')
      STALE_LIST="${STALE_LIST}- ${TITLE:-drawer_${drawer_id}} — last_compiled: $LAST_COMPILED (${AGE_DAYS}일 전)\n"
    fi
  done < <(sqlite3 "$SQLITE_DB" \
    "SELECT id, content FROM drawers WHERE wing = 'wing_knowledge' LIMIT 200" \
    2>/dev/null || true)
fi

# Fallback: _cache 내 .md 파일 검색
if [ "$STALE_COUNT" -eq 0 ]; then
  while IFS= read -r drawer; do
    LAST_COMPILED=$(grep -oE "last_compiled:[[:space:]]*[0-9]{2}/[0-9]{2}/[0-9]{2}" "$drawer" 2>/dev/null | head -1 | grep -oE "[0-9]{2}/[0-9]{2}/[0-9]{2}")
    [ -z "$LAST_COMPILED" ] && continue

    YY="${LAST_COMPILED:0:2}"
    MM="${LAST_COMPILED:3:2}"
    DD="${LAST_COMPILED:6:2}"
    COMPILED_EPOCH=$(date -d "20${YY}-${MM}-${DD}" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    AGE_DAYS=$(( (NOW_EPOCH - COMPILED_EPOCH) / 86400 ))

    if [ "$AGE_DAYS" -gt "$STALE_DAYS" ]; then
      STALE_COUNT=$((STALE_COUNT + 1))
      STALE_LIST="${STALE_LIST}- $(basename "$drawer") — last_compiled: $LAST_COMPILED (${AGE_DAYS}일 전)\n"
    fi
  done < <(find "$CACHE_DIR" "$PALACE" -maxdepth 3 -type f -name "*.md" \
    -path "*wing_knowledge*" 2>/dev/null | head -50)
fi

# 리포트 생성
{
  echo "# Stale Drawer Report — $(date +%y/%m/%d)"
  echo ""
  echo "기준: last_compiled가 ${STALE_DAYS}일 이상 지난 drawer"
  echo "대상 wing: wing_knowledge"
  echo ""
  echo "**검출**: ${STALE_COUNT}건"
  echo ""
  if [ "$STALE_COUNT" -gt 0 ]; then
    echo "## 대상 목록"
    echo -e "$STALE_LIST"
    echo ""
    echo "## 권장 조치"
    echo "- 각 drawer의 타임라인에 최근 증거가 있는지 확인"
    echo "- 있다면 → Compiled Truth 섹션 재작성 + last_compiled 갱신"
    echo "- 없다면 → 여전히 유효한 지식인지 검토, 필요시 supersedes 체인 확인"
    echo ""
    echo "→ 다음 단계: MemPalace에서 해당 drawer 열어 검토"
  else
    echo "모든 wing_knowledge drawer가 최신 상태 (또는 wing_knowledge 비어있음)."
    echo "→ 다음 단계: 없음 (다음 주 자동 재실행)"
  fi
} > "$REPORT"

# 출력 (Seeing like an agent: 상태+다음액션 포함)
if [ "$STALE_COUNT" -gt 0 ]; then
  echo "⚠️  Stale drawer ${STALE_COUNT}건 감지 → $REPORT"
  echo "→ 조치: MemPalace에서 해당 drawer Compiled Truth 재작성 권장"
  exit 0  # 경고만, 세션 차단 금지
else
  echo "✅ Stale drawer 없음 (wing_knowledge ${STALE_DAYS}일 기준)"
fi
