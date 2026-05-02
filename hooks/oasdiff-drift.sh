#!/usr/bin/env bash
# oasdiff-drift.sh — PostToolUse(Edit|Write) 훅 [Phase 2]
# OpenAPI 파일 변경 시 oasdiff로 breaking change 정밀 감지
# oasdiff 미설치 + go 있을 시 백그라운드 자동 설치
# 원칙: <5s, silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

# openapi*.yaml 파일 필터
FP=$(python3 - 2>/dev/null <<'PYEOF'
import json, os, re, sys
payload = json.loads(os.environ.get("HOOK_PAYLOAD", "{}"))
fp = (payload.get("tool_input", {}).get("file_path") or payload.get("file_path") or "")
name = os.path.basename(fp).lower()
if re.match(r"openapi.*\.ya?ml$", name) and os.path.exists(fp):
    print(fp)
PYEOF
)
[ -z "$FP" ] && exit 0

# oasdiff 바이너리 탐색 (PATH + ~/go/bin)
OASDIFF_BIN=$(command -v oasdiff 2>/dev/null)
[ -z "$OASDIFF_BIN" ] && [ -x "$HOME/go/bin/oasdiff" ] && OASDIFF_BIN="$HOME/go/bin/oasdiff"

if [ -z "$OASDIFF_BIN" ]; then
    # go 있으면 백그라운드 자동 설치
    if command -v go >/dev/null 2>&1; then
        nohup go install github.com/tufin/oasdiff@latest >/dev/null 2>&1 &
        obs_append oasdiff-autoinstall info '{"status":"bg-install-triggered","tool":"oasdiff"}' 2>/dev/null || true
    fi
    exit 0
fi

export FP OASDIFF_BIN

python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, subprocess, pathlib, sys

fp = os.environ.get("FP", "")
oasdiff = os.environ.get("OASDIFF_BIN", "oasdiff")
name = os.path.basename(fp)

snap_dir = pathlib.Path.home() / ".claude" / "_cache" / "drift" / "openapi-snapshots"
snap_dir.mkdir(parents=True, exist_ok=True)
snap_path = snap_dir / (name + ".baseline.yaml")

with open(fp, "rb") as f:
    content = f.read()

# 첫 실행 — 스냅샷 저장
if not snap_path.exists():
    snap_path.write_bytes(content)
    sys.exit(0)

# 내용 동일 — skip
if snap_path.read_bytes() == content:
    sys.exit(0)

try:
    result = subprocess.run(
        [oasdiff, "breaking", str(snap_path), fp],
        capture_output=True, text=True, timeout=8
    )
    breaking = result.stdout.strip()
except Exception:
    sys.exit(0)

if breaking:
    count = len(breaking.splitlines())
    preview = breaking[:400]
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": f"[oasdiff] {name}: breaking change {count}건 감지 — merge 전 승인 필요\n{preview}"
        }
    }))
else:
    # compatible change → 스냅샷 갱신
    snap_path.write_bytes(content)
PYEOF

exit 0
