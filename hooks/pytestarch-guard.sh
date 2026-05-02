#!/usr/bin/env bash
# pytestarch-guard.sh — PostToolUse(Edit|Write) 훅 [Phase 2]
# domain/application/infrastructure 레이어 Python 파일 변경 시 아키텍처 규칙 검사
# pytestarch 미설치 시 pip 자동 설치 (백그라운드)
# 원칙: <5s, silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

# 레이어 Python 파일 필터 (domain/application/infrastructure 한정)
FP=$(python3 - 2>/dev/null <<'PYEOF'
import json, os
payload = json.loads(os.environ.get("HOOK_PAYLOAD", "{}"))
fp = (payload.get("tool_input", {}).get("file_path") or payload.get("file_path") or "")
path_l = fp.replace("\\", "/").lower()
if (fp.endswith(".py")
        and any(seg in path_l for seg in ["/domain/", "/application/", "/infrastructure/"])
        and os.path.exists(fp)):
    print(fp)
PYEOF
)
[ -z "$FP" ] && exit 0

# pytestarch 설치 확인
if ! python3 -c "import pytestarch" >/dev/null 2>&1; then
    PIP_CMD=$(command -v pip3 2>/dev/null || command -v pip 2>/dev/null)
    if [ -n "$PIP_CMD" ]; then
        nohup "$PIP_CMD" install pytestarch --quiet >/dev/null 2>&1 &
        obs_append pytestarch-autoinstall info '{"status":"bg-install-triggered"}' 2>/dev/null || true
    fi
    exit 0
fi

export FP

python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, sys, pathlib

fp = os.environ.get("FP", "")
path_l = fp.replace("\\", "/").lower()

try:
    from pytestarch import get_evaluable_architecture, Rule

    # 프로젝트 루트 탐색 (domain|application|infrastructure 의 부모)
    parts = pathlib.Path(fp).parts
    root = None
    for i, p in enumerate(parts):
        if p in ("domain", "application", "infrastructure"):
            root = str(pathlib.Path(*parts[:i]))
            break

    if not root or not pathlib.Path(root).exists():
        sys.exit(0)

    arch = get_evaluable_architecture(root, root)

    violations = []
    rules = [
        (
            Rule()
            .modules_that().are_named("domain")
            .should_not()
            .import_modules_that().are_named("infrastructure"),
            "domain → infrastructure import 금지"
        ),
        (
            Rule()
            .modules_that().are_named("domain")
            .should_not()
            .import_modules_that().are_named("application"),
            "domain → application import 금지"
        ),
    ]

    for rule, desc in rules:
        try:
            result = arch.evaluate(rule)
            if result:
                violations.append(f"  ✗ {desc}: {str(result)[:200]}")
        except Exception:
            pass

    if violations:
        viol_str = "\n".join(violations)
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": f"[pytestarch] 아키텍처 위반 감지 ({len(violations)}건)\n{viol_str}"
            }
        }))
    else:
        # 정상 — obs 기록만 (출력 없음)
        pass

except ImportError:
    pass
except Exception:
    pass
PYEOF

exit 0
