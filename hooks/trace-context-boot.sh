#!/usr/bin/env bash
# trace-context-boot.sh — SessionStart 훅
# 세션 시작 시 OTel 환경 힌트, Langfuse 로컬 ping, session-start 이벤트 기록
# 원칙: 조용히, <500ms, 실패 silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

# 리소스 가드 — 여유 없으면 skip
obs_resource_check || exit 0

SESSION_ID=$(obs_session_id)
CWD=$(pwd 2>/dev/null || echo "unknown")

# session-start 이벤트 기록
obs_append session-start info "$(python3 - 2>/dev/null <<PYEOF
import json, os
print(json.dumps({
    "session": "${SESSION_ID}",
    "cwd": "${CWD}",
    "otel_service": os.environ.get("OTEL_SERVICE_NAME", "claude-code-mgtg"),
    "pid": ${$}
}))
PYEOF
)"

# Langfuse 로컬 ping (best-effort, 1초 timeout)
LANGFUSE_HOST="${LANGFUSE_HOST:-}"
if [ -n "$LANGFUSE_HOST" ] && command -v curl >/dev/null 2>&1; then
    if curl -sf --max-time 1 "${LANGFUSE_HOST}/api/public/health" >/dev/null 2>&1; then
        obs_append langfuse-ping info '{"status":"up"}'
    else
        # 조용히 — Langfuse 미기동은 정상 케이스 (Phase 1 기본)
        :
    fi
fi

exit 0
