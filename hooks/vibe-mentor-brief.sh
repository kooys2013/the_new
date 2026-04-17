#!/bin/bash
# vibe-mentor-brief.sh — vibe-sunsang TIMELINE.md 최근 1줄 요약
# session-briefing.sh에서 호출

VIBE_DIR="$HOME/vibe-sunsang"
EXPORTS="$VIBE_DIR/exports/latest.md"
TIMELINE="$VIBE_DIR/growth-log/TIMELINE.md"

[ ! -d "$VIBE_DIR" ] && exit 0

echo "┌─── Vibe Mentor (어제 기준) ───────────────┐"

if [ -f "$TIMELINE" ]; then
  LAST=$(tail -n 30 "$TIMELINE" 2>/dev/null | grep -E 'L[0-9]' | tail -1 | head -c 120)
  [ -n "$LAST" ] && echo "│ 📊 $LAST"
fi

# 주간 FIT 제안 대기 체크
PENDING="$HOME/.claude/_cache/weekly-fit-pending.md"
if [ -f "$PENDING" ]; then
  echo "│ ⚡ 주간 FIT 제안 대기 — bash ~/.claude/hooks/apply-weekly-fit.sh <A|B|C>"
fi

echo "└────────────────────────────────────────────┘"
exit 0
