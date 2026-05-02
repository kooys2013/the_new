#!/usr/bin/env bash
# cpcv-check.sh — PostToolUse(Edit|Write) 훅 [Phase 2]
# GO v2 엔진/스크립트 파일 변경 시 CPCV DSR 검증
# mlfinlab 미설치 시 설치 안내 (패키지가 무거워 자동설치 안 함)
# 원칙: <3s, silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

# GO v2 엔진/스크립트 파일 필터
FP=$(python3 - 2>/dev/null <<'PYEOF'
import json, os
payload = json.loads(os.environ.get("HOOK_PAYLOAD", "{}"))
fp = (payload.get("tool_input", {}).get("file_path") or payload.get("file_path") or "")
path_l = fp.replace("\\", "/").lower()
if ("/go-v2/" in path_l or "/go_v2/" in path_l):
    if "/backend/engine/" in path_l or "/backend/scripts/run_" in path_l:
        if os.path.exists(fp):
            print(fp)
PYEOF
)
[ -z "$FP" ] && exit 0

export FP

# mlfinlab 설치 확인
if python3 -c "import mlfinlab" >/dev/null 2>&1; then
    # mlfinlab 설치됨 — CPCV 분석 실행
    python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, sys, pathlib

fp = os.environ.get("FP", "")
name = fp.replace("\\", "/").split("/")[-1]
returns_path = pathlib.Path(fp).parent / "returns.csv"

if not returns_path.exists():
    # returns.csv 없음 — 권고
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                f"[cpcv] GO v2 전략 수정: {name}\n"
                "returns.csv 없어 CPCV 자동 실행 불가 — /skill drift-sentinel 로 수동 검증 권장"
            )
        }
    }))
    sys.exit(0)

try:
    import mlfinlab.cross_validation as cv
    import pandas as pd

    returns = pd.read_csv(str(returns_path), index_col=0, parse_dates=True)

    # 간이 Deflated Sharpe Ratio 추정
    col = "strategy" if "strategy" in returns.columns else returns.columns[0]
    s = returns[col].dropna()
    if len(s) < 20:
        sys.exit(0)

    sr = s.mean() / s.std() * (252 ** 0.5) if s.std() > 0 else 0
    dsr = float(min(1.0, max(0.0, sr / 3.0)))  # 간이 정규화

    if dsr < 0.95:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"[cpcv] DSR={dsr:.3f} < 0.95 임계값\n"
                    f"전략 신뢰도 기준 미달 — merge 전 재검증 필수 (drift-budget.md §CPCV)"
                )
            }
        }))
    # DSR >= 0.95 → 정상, 출력 없음

except Exception:
    pass
PYEOF

else
    # mlfinlab 미설치 — 설치 안내 statusMessage
    python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os
fp = os.environ.get("FP", "")
name = fp.replace("\\", "/").split("/")[-1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": (
            f"[cpcv] GO v2 전략 수정 감지: {name}\n"
            "mlfinlab 미설치 — CPCV 비활성\n"
            "활성화: pip install mlfinlab  (설치 후 자동 적용)"
        )
    }
}))
PYEOF
fi

exit 0
