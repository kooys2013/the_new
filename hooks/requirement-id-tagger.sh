#!/usr/bin/env bash
# requirement-id-tagger.sh — UserPromptSubmit 훅
# 프롬프트에서 (REQ|GO|KORENO)-\d{3,} 패턴 매칭
# 발견 시 additionalContext에 "컨텍스트: REQ-xxx" 주입 + traceability-weaver 힌트
# 원칙: <50ms, exit 0 필수 (prompt 차단 금지)

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

# stdin payload 수집 (환경변수로 Python에 전달 — shell injection 차단)
HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

RESULT=$(python3 - 2>/dev/null <<'PYEOF'
import json, re, sys, os

payload_raw = os.environ.get("HOOK_PAYLOAD", "{}")
try:
    payload = json.loads(payload_raw)
except Exception:
    payload = {}

prompt = (
    payload.get("prompt")
    or payload.get("user_prompt")
    or ""
)

# 정규식 매칭 (대소문자 민감 — rules/traceability-contract.md NEVER 위반 방지)
full_matches = re.findall(r"(?:REQ|GO|KORENO)-\d{3,}", prompt)

# dedupe preserving order
seen = set()
unique = []
for m in full_matches:
    if m not in seen:
        seen.add(m)
        unique.append(m)

if not unique:
    sys.exit(0)

ctx_line = "컨텍스트: " + ", ".join(unique) + " (traceability-weaver로 매트릭스 확인 가능)"

# 1줄: obs 기록용 meta JSON
print(json.dumps({"ids": unique, "context": ctx_line}))
# 2줄: hook output JSON (additionalContext)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ctx_line
    }
}))
PYEOF
)

if [ -n "$RESULT" ]; then
    META=$(echo "$RESULT" | head -1)
    HOOK_OUT=$(echo "$RESULT" | tail -1)

    obs_append trace-prompt-tag info "$META" 2>/dev/null || true
    printf '%s\n' "$HOOK_OUT"
fi

exit 0
