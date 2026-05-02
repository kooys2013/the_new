#!/usr/bin/env bash
# drift-baseline-loader.sh — SessionStart 훅
# _cache/drift/baseline.json 로드 or 최초 실행 시 빈 스냅샷 생성
# 원칙: 조용히, baseline 없으면 초기화만 (자동 수정 금지 — rules/drift-budget.md ALWAYS)

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

BASELINE="${CLAUDE_DRIFT_DIR:-$HOME/.claude/_cache/drift}/baseline.json"
mkdir -p "$(dirname "$BASELINE")" 2>/dev/null || exit 0

if [ ! -f "$BASELINE" ]; then
    # 최초 실행 — 빈 baseline 초기화
    python3 - "$BASELINE" <<'PYEOF' 2>/dev/null || exit 0
import json, sys, datetime
path = sys.argv[1]
data = {
    "version": 1,
    "created_at": datetime.datetime.utcnow().isoformat() + "Z",
    "openapi": {},
    "architecture": {
        "layers": [],
        "forbidden_imports": {}
    },
    "go_v2": {
        "strategy_cpcv_required": True,
        "dsr_threshold": 0.95
    }
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PYEOF
    obs_append drift-baseline-init info '{"reason":"first-run","path":"'"$BASELINE"'"}'
else
    # 존재 확인만 — 내용 로드는 skill이 담당
    obs_append drift-baseline-load info "$(python3 - "$BASELINE" 2>/dev/null <<'PYEOF'
import json, sys, os
path = sys.argv[1]
size = os.path.getsize(path)
try:
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    openapi_n = len(d.get("openapi", {}))
    print(json.dumps({"size": size, "openapi_entries": openapi_n}))
except Exception:
    print(json.dumps({"size": size, "error": "parse"}))
PYEOF
)"
fi

exit 0
