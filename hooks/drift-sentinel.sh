#!/usr/bin/env bash
# drift-sentinel.sh — PostToolUse(Edit|Write) 훅
# 경량 drift 감지: OpenAPI sha256 변경 / GO v2 model 파일 / 아키텍처 레이어 위반 힌트
# 무거운 분석은 skill(drift-sentinel)에 위임 — statusMessage로 제안만
# 원칙: <3s, silent exit 0, baseline.json 자동 수정 금지

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

# stdin payload 수집 (환경변수로 Python에 전달 — shell injection 차단)
HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

DETECT=$(python3 - 2>/dev/null <<'PYEOF'
import json, sys, os, hashlib, pathlib, re

payload_raw = os.environ.get("HOOK_PAYLOAD", "{}")
try:
    payload = json.loads(payload_raw)
except Exception:
    payload = {}

# PostToolUse payload 구조:
# { "tool_input": {"file_path": "..."} } 또는 { "file_path": "..." }
fp = (
    payload.get("tool_input", {}).get("file_path")
    or payload.get("file_path")
    or ""
)

if not fp or not os.path.exists(fp):
    sys.exit(0)

# 카테고리 분류
name = os.path.basename(fp).lower()
path_l = fp.replace("\\", "/").lower()

cat = None
if re.match(r"openapi.*\.ya?ml$", name):
    cat = "api"
elif "/go-v2/" in path_l or "/go_v2/" in path_l:
    if "/backend/engine/" in path_l or "/backend/scripts/run_" in path_l:
        cat = "model-go-v2"
    else:
        cat = "model-go-v2-other"
elif any(seg in path_l for seg in ["/domain/", "/application/", "/infrastructure/"]):
    cat = "arch"
else:
    sys.exit(0)  # drift 대상 아님

# sha256 계산
try:
    with open(fp, "rb") as f:
        sha = hashlib.sha256(f.read()).hexdigest()
except Exception:
    sys.exit(0)

# baseline 로드
baseline_path = pathlib.Path.home() / ".claude" / "_cache" / "drift" / "baseline.json"
prev_sha = None
if baseline_path.exists():
    try:
        bl = json.loads(baseline_path.read_text(encoding="utf-8"))
        if cat == "api":
            prev_sha = bl.get("openapi", {}).get(name)
    except Exception:
        pass

# 심각도 판정 (경량 — 훅 단계)
severity = "info"
reason = "changed"
status_msg = ""

if cat == "api":
    if prev_sha and prev_sha != f"sha256:{sha}":
        severity = "warn"
        status_msg = "openapi.yaml 변경 감지 — /skill drift-sentinel 심층 분석 권장 (oasdiff)"
    elif not prev_sha:
        reason = "no-baseline"

elif cat == "model-go-v2":
    severity = "info"
    status_msg = "GO v2 engine/scripts 수정 — CPCV DSR ≥ 0.95 재검증 권장"

elif cat == "arch":
    if "/domain/" in path_l and fp.endswith(".py"):
        try:
            with open(fp, encoding="utf-8", errors="ignore") as f:
                content = f.read(50000)
            if re.search(r"from\s+infrastructure|import\s+infrastructure", content):
                severity = "warn"
                reason = "domain-imports-infra"
                status_msg = "domain 레이어에서 infrastructure import 감지 — /skill drift-sentinel"
        except Exception:
            pass

out = {
    "file": fp,
    "category": cat,
    "sha256": sha[:16] + "...",
    "severity": severity,
    "reason": reason,
}

print(json.dumps(out))
if status_msg:
    print(status_msg)
PYEOF
)

[ -z "$DETECT" ] && exit 0

META=$(echo "$DETECT" | head -1)
STATUS_MSG=$(echo "$DETECT" | tail -n +2 | head -1)
SEV=$(echo "$META" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('severity','info'))" 2>/dev/null || echo "info")

obs_append drift-detect "$SEV" "$META" 2>/dev/null || true

# statusMessage 권고 (warn 이상만)
if [ -n "$STATUS_MSG" ] && [ "$SEV" != "info" ]; then
    export STATUS_MSG
    python3 - 2>/dev/null <<'PYEOF' || true
import json, os
msg = os.environ.get("STATUS_MSG", "")
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": f"[drift-sentinel] {msg}"
    }
}))
PYEOF
fi

exit 0
