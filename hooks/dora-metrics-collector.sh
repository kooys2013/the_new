#!/usr/bin/env bash
# dora-metrics-collector.sh — Stop 훅에서 DORA 메트릭 수집
# git log 기반 배포 빈도 + revert 비율 측정 → _state/dora-metrics.jsonl
# 빠름: ≤100ms (git log --oneline만 사용)

set -euo pipefail

STATE_DIR="$HOME/.claude/_state"
mkdir -p "$STATE_DIR"
METRICS_FILE="$STATE_DIR/dora-metrics.jsonl"

# git repo 여부 확인
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# 오늘 커밋 수
TODAY_COMMITS=$(git log --oneline --since="24 hours ago" 2>/dev/null | wc -l | tr -d ' ')

# 오늘 revert/hotfix 커밋 수
TODAY_FAILS=$(git log --oneline --since="24 hours ago" 2>/dev/null | grep -iE "revert|hotfix" | wc -l | tr -d ' ')

# 기록
echo "{\"ts\":\"$(date -Iseconds)\",\"commits\":$TODAY_COMMITS,\"fail_commits\":$TODAY_FAILS,\"repo\":\"$(basename $(git rev-parse --show-toplevel 2>/dev/null))\"}" \
  >> "$METRICS_FILE"

# 변경 실패율 임계 알림 (15%+)
if [[ $TODAY_COMMITS -gt 0 ]]; then
  FAIL_RATE=$(( TODAY_FAILS * 100 / TODAY_COMMITS ))
  if [[ $FAIL_RATE -ge 15 ]]; then
    OBS_DIR="$HOME/.claude/_cache/obs"
    mkdir -p "$OBS_DIR"
    WEEK=$(date +%Y-%W)
    echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"dora-fail-rate-high\",\"rate\":$FAIL_RATE}" \
      >> "$OBS_DIR/${WEEK}.jsonl"
  fi
fi

exit 0
