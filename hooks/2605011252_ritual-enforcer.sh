#!/usr/bin/env bash
# Z-1 7일 의례 — SessionStart enforcer
# 이벤트: SessionStart / SLA: ≤500ms / silent exit 0 — 세션 블로킹 금지
# 역할: baseline 존재 확인 + D+7 도달 시 평가 미실행 알림

set -u
exec 2>/dev/null

CLAUDE_DIR="${HOME}/.claude"
STATE_DIR="${CLAUDE_DIR}/_state"
REPORT_DIR="${CLAUDE_DIR}/_report"
BASELINE="${STATE_DIR}/baseline-2605011250.json"
EVAL_REPORT="${REPORT_DIR}/2605081300_7day-validation.md"

# baseline 없으면 의례 비활성 → silent
[ -f "${BASELINE}" ] || exit 0

# 현재 날짜 (YYYY-MM-DD)
TODAY=$(date '+%Y-%m-%d' 2>/dev/null || exit 0)
END_DATE="2026-05-08"

# D+7 도달 + 평가 보고서 미생성 → 한 줄 알림
case "$TODAY" in
  2026-05-08|2026-05-09|2026-05-1[0-9]|2026-05-2[0-9]|2026-05-3[01]|2026-0[6-9]-*|2026-1[0-2]-*|202[7-9]-*)
    if [ ! -f "${EVAL_REPORT}" ]; then
      echo "[Z-1 Ritual] D+7 도달 — 7day-evaluation.sh 미실행. 수동 실행 권장: bash ~/.claude/hooks/2605011251_7day-evaluation.sh"
    fi
    ;;
  *)
    # D+0~D+6: 진행 표시만 (statusMessage 대체)
    ;;
esac

exit 0
