#!/usr/bin/env bash
# ux-rehearsal-suggest.sh — Stop 훅
# history.jsonl 최근 N건에서 *-generator 스킬 호출 감지 시
# statusMessage로 /skill ux-rehearsal 권고 (실행하지 않음 — 권고만)
# 원칙: <500ms, silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init
obs_resource_check || exit 0

HISTORY="${CLAUDE_HISTORY:-$HOME/.claude/history.jsonl}"
[ -f "$HISTORY" ] || exit 0

export HISTORY
DETECT=$(python3 - 2>/dev/null <<'PYEOF'
import json, re, sys, os

path = os.environ.get("HISTORY", "")
try:
    with open(path, encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()[-20:]
except Exception:
    sys.exit(0)

gen_skills = set()
for line in lines:
    try:
        rec = json.loads(line)
    except Exception:
        continue
    text = json.dumps(rec, ensure_ascii=False)
    matches = re.findall(r"([a-z-]+-generator)", text, re.IGNORECASE)
    for m in matches:
        gen_skills.add(m.lower())

if not gen_skills:
    sys.exit(0)

skills_str = ", ".join(sorted(gen_skills)[:3])
print(json.dumps({"generators": sorted(gen_skills), "count": len(gen_skills)}))
print(f"최근 generator 스킬({skills_str}) 산출물이 있습니다 — /skill ux-rehearsal 권고")
PYEOF
)

[ -z "$DETECT" ] && exit 0

META=$(echo "$DETECT" | head -1)
MSG=$(echo "$DETECT" | tail -n +2 | head -1)

obs_append ux-suggest info "$META" 2>/dev/null || true

if [ -n "$MSG" ]; then
    export MSG
    python3 - 2>/dev/null <<'PYEOF' || true
import json, os
msg = os.environ.get("MSG", "")
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "Stop",
        "additionalContext": f"[ux-rehearsal] {msg}"
    }
}))
PYEOF
fi

exit 0
