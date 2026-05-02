#!/usr/bin/env bash
# risk-asset-router.sh — PostToolUse(Edit|Write) A위험도 자산 변경 force 라우팅
# Gap 10 (결정론적 라우팅) 부분 적용 — 자금 직결만 force, 일반 코딩은 LLM 매칭 유지
# A위험도 정의: risk_gate.py / kill_switch.py / convex_sizer.py (사용자 합의)

set -euo pipefail

TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    inp = d.get('tool_input',{})
    print(inp.get('file_path','') or inp.get('path',''))
except:
    print('')
" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" ]] && exit 0

# A위험도 자산 정규식 (정확 매칭 — backtest_engine.py 등 다른 파일 오인 방지)
RISK_PATTERN='(risk_gate|kill_switch|convex_sizer)\.py$'

if ! echo "$FILE_PATH" | grep -qE "$RISK_PATTERN"; then
  exit 0
fi

# A위험도 매칭 → 강제 라우팅 권고
ASSET=$(basename "$FILE_PATH")

cat <<EOF
{"additionalContext": "🚨 [risk-asset-router] A위험도 자산 변경 감지: ${ASSET}\n자금 직결 모듈 — 다음 검증 자동 진입 필수:\n1. coverage-gate (95% 강제, 일반 80%보다 엄격)\n2. mutation-test (mutation_score ≥ 80%)\n3. trading-safety-tester (Order idempotency / Kill-switch SLA / Position reconciliation / Pre-trade risk gate)\n4. vv-separator (의도-구현 V&V, fresh subagent)\n5. /verify L5 컨센트 (서브에이전트 0.05~5 USD)\n현재 R1 정책: 트레이딩 진입 신호 결정에는 자동 게이트 개입 금지. 자금 게이트 코드 자체 검증만 force."}
EOF

# obs 이벤트
OBS_DIR="$HOME/.claude/_cache/obs"
mkdir -p "$OBS_DIR"
WEEK=$(date +%Y-%W)
echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"risk-asset-edit\",\"file\":\"${ASSET}\"}" \
  >> "$OBS_DIR/${WEEK}.jsonl"

exit 0
