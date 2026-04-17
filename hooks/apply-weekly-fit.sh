#!/bin/bash
# apply-weekly-fit.sh <A|B|C> — 주간 FIT 제안 적용
# 승인된 옵션의 patch + git 커밋 + 성장일지 엔트리

set -uo pipefail
OPT="${1:-}"
CACHE_DIR="$HOME/.claude/_cache"
PENDING="$CACHE_DIR/weekly-fit-pending.md"
SNAPSHOT_DIR="$CACHE_DIR/fit-snapshots"
mkdir -p "$SNAPSHOT_DIR"

[ -z "$OPT" ] && { echo "사용법: $0 <A|B|C>"; exit 1; }
[ ! -f "$PENDING" ] && { echo "대기 중인 제안 없음"; exit 0; }

TS=$(date +%y%m%d_%H%M)

case "$OPT" in
  A)
    echo "[A] 최약 축 트리거 warn → block 승격"
    # 베이스라인 TIMELINE 스냅샷
    [ -f "$HOME/vibe-sunsang/growth-log/TIMELINE.md" ] && \
      cp "$HOME/vibe-sunsang/growth-log/TIMELINE.md" "$SNAPSHOT_DIR/TIMELINE_$TS.md"
    # 실제 patch는 사용자가 최약 축 확인 후 수동 편집 (안전)
    echo "→ rules/auto-triggers.md에서 최약 축 WHEN절에 'block' 추가"
    echo "→ 예: PreToolUse(Edit) 훅에서 2회 실패 시 exit 1"
    ;;
  B)
    echo "[B] 해당 축 관련 훅 신설"
    echo "→ hooks/pre-edit-guard.sh 템플릿 생성 안내"
    ;;
  C)
    echo "[C] 보류 — 다음 주 재평가"
    ;;
  *)
    echo "알 수 없는 옵션: $OPT"; exit 1 ;;
esac

# 성장일지 엔트리
GROWTH="$HOME/.mempalace/growth-log.md"
if [ -f "$GROWTH" ]; then
  echo "" >> "$GROWTH"
  echo "## $(date +%y/%m/%d) 주간 FIT 적용: 옵션 $OPT" >> "$GROWTH"
  echo "- 스냅샷: $SNAPSHOT_DIR/TIMELINE_$TS.md" >> "$GROWTH"
fi

# pending 해제
mv "$PENDING" "$CACHE_DIR/weekly-fit-applied-$TS.md" 2>/dev/null || true

echo "완료. 1주일 뒤 효과 측정 — weekly-fit-analyzer.sh 재실행 시 자동 diff"
