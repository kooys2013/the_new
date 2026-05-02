#!/usr/bin/env bash
# dependency-drift-monitor.sh — 의존성 drift 감시 (카테고리 E)
# 트리거 A: Task Scheduler 매주 월요일 09:00 (주간 리포트)
# 트리거 B: PostToolUse(Edit/Write) on package.json|requirements.txt|go.mod|Cargo.toml
# 출력: _cache/codex-automations/dep-drift-YYWW.md
# 원칙: <30s, silent exit 0, GREEN-only (PostToolUse), NEVER npm install/update

export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || true
type obs_init >/dev/null 2>&1 && obs_init

OUTPUT_DIR="$HOME/.claude/_cache/codex-automations"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || exit 0

# ── 모드 판별: PostToolUse vs Task Scheduler ──────────────────────────────
HOOK_PAYLOAD=$(cat 2>/dev/null || echo '{}')
export HOOK_PAYLOAD

TRIGGER_FILE=$(python3 - 2>/dev/null <<'PYEOF'
import json, os, pathlib
try:
    p = json.loads(os.environ.get("HOOK_PAYLOAD", "{}"))
    fp = ((p.get("tool_input") or {}).get("file_path", "")
          or (p.get("tool_input") or {}).get("path", ""))
    print(pathlib.Path(fp).name if fp else "__scheduler__")
except Exception:
    print("__scheduler__")
PYEOF
)

# PostToolUse 모드: 의존성 파일인지 확인
DEP_PATTERN="^(package\.json|requirements\.txt|go\.mod|Cargo\.toml|poetry\.lock|Pipfile|yarn\.lock|pnpm-lock\.yaml)$"
POSTTOOL_MODE=false
if [ "$TRIGGER_FILE" != "__scheduler__" ]; then
    echo "$TRIGGER_FILE" | grep -qE "$DEP_PATTERN" && POSTTOOL_MODE=true || exit 0
fi

# PostToolUse는 GREEN usage gate 필수 (scheduler는 항상 실행)
USAGE_LEVEL="${CLAUDE_USAGE_LEVEL:-GREEN}"
if [ "$POSTTOOL_MODE" = "true" ] && [ "$USAGE_LEVEL" != "GREEN" ]; then
    exit 0
fi

# ── 주간 태그 + 출력 파일 경로 ────────────────────────────────────────────
WEEK_TAG=$(date +%y%V)
OUTPUT_FILE="$OUTPUT_DIR/dep-drift-${WEEK_TAG}.md"

# 스케줄러 모드 + 이미 이번 주 생성됨 → skip
if [ -f "$OUTPUT_FILE" ] && [ "$POSTTOOL_MODE" = "false" ]; then
    type obs_event >/dev/null 2>&1 && obs_event "codex-automations" "dep-drift-skip" \
      '{"reason":"already_exists_week","ts":"'$(date -Iseconds)'"}'
    exit 0
fi

CWD=$(pwd)
export CWD POSTTOOL_MODE TRIGGER_FILE OUTPUT_FILE WEEK_TAG

# ── Python: 스택 탐지 + npm audit + git log + 리포트 생성 ─────────────────
STATUS_INFO=$(timeout 25 python3 - 2>/dev/null <<'PYEOF'
import os, json, pathlib, datetime, subprocess, sys, re, shutil

CWD = pathlib.Path(os.environ.get("CWD", "."))
OUTPUT_FILE = pathlib.Path(os.environ["OUTPUT_FILE"])
POSTTOOL_MODE = os.environ.get("POSTTOOL_MODE") == "true"
TRIGGER_FILE = os.environ.get("TRIGGER_FILE", "")
WEEK_TAG = os.environ.get("WEEK_TAG", datetime.datetime.now().strftime("%y%V"))
now_str = datetime.datetime.now().isoformat(timespec="seconds")

# 1. 프로젝트 스택 탐지 (cwd + 상위 3레벨)
def detect_stack(d):
    s = []
    if (d / "package.json").exists(): s.append("node")
    if (d / "requirements.txt").exists() or (d / "pyproject.toml").exists(): s.append("python")
    if (d / "go.mod").exists(): s.append("go")
    if (d / "Cargo.toml").exists(): s.append("rust")
    return s

stacks = detect_stack(CWD)
if not stacks:
    for parent in list(CWD.parents)[:3]:
        stacks = detect_stack(parent)
        if stacks:
            CWD = parent
            break

if not stacks:
    sys.exit(0)  # dep 파일 없는 환경 → silent exit

# 2. git log — 최근 7일 dep 파일 변경
dep_changes = []
try:
    since = (datetime.datetime.now() - datetime.timedelta(days=7)).strftime("%Y-%m-%d")
    res = subprocess.run(
        ["git", "log", f"--since={since}", "--oneline", "--",
         "package.json", "requirements.txt", "go.mod", "Cargo.toml",
         "poetry.lock", "Pipfile", "yarn.lock", "pnpm-lock.yaml"],
        capture_output=True, text=True, timeout=5, cwd=str(CWD)
    )
    dep_changes = [l.strip() for l in res.stdout.splitlines() if l.strip()][:10]
except Exception:
    pass

# 3. npm audit (node 프로젝트)
audit_findings = []
audit_label = "Unknown"

if "node" in stacks:
    try:
        # Windows: npm은 .cmd 확장자 필요 (shutil.which로 자동 감지)
        npm_cmd = shutil.which("npm.cmd") or shutil.which("npm") or "npm"
        res = subprocess.run(
            [npm_cmd, "audit", "--json", "--audit-level=low"],
            capture_output=True, text=True, timeout=15, cwd=str(CWD)
        )
        raw = res.stdout.strip()
        if raw:
            data = json.loads(raw)
            vulns = data.get("vulnerabilities") or {}
            for pkg, info in list(vulns.items())[:15]:
                sev = info.get("severity", "unknown")
                via = info.get("via") or []
                title = (via[0].get("title", "unknown") if via and isinstance(via[0], dict)
                         else str(via[0]) if via else "unknown")
                audit_findings.append({"pkg": pkg, "severity": sev, "title": title})
        audit_label = "observed"
    except Exception as e:
        audit_label = f"Unknown (실패: {type(e).__name__})"

# 4. 보안 critical/high 판정
critical_vulns = [f for f in audit_findings if f["severity"] in ("critical", "high")]
mode_label = "PostToolUse 즉시 감지" if POSTTOOL_MODE else "Task Scheduler 주간 집계"

# 5. 리포트 생성
lines = [
    f"# Dependency Drift — {WEEK_TAG}",
    "",
    "> Evidence Rules (E1-E6) 준수.",
    f"> 인용: `git-log[{now_str}]` / `npm-audit[{now_str}]` / `cwd:{CWD}`",
    "> 라벨: `[observed]` 직접 측정 / `[suspected]` 간접 추론 / `[inferred]` 논리 도출",
    "",
    "## Summary",
    f"- 모드: **{mode_label}** [observed]",
    f"- 스택: `{', '.join(stacks)}` (인용: `cwd:{CWD}`) [observed]",
    f"- 최근 7일 dep 파일 변경: **{len(dep_changes)}건** [observed]",
]
if audit_label == "observed":
    lines.append(f"- 보안 취약점: **{len(audit_findings)}건** (critical/high: {len(critical_vulns)}건) [observed]")
else:
    lines.append(f"- npm audit: {audit_label} [Unknown]")

lines += ["", "## Dependency File Changes (최근 7일)"]
if dep_changes:
    for c in dep_changes:
        lines.append(f"- `{c}` [observed]")
else:
    lines.append("- 없음 (git log 결과 0건) [observed]")

if "node" in stacks:
    lines += ["", "## Security Audit (npm audit)"]
    if audit_label != "observed":
        lines.append(f"- {audit_label}")
        lines.append("  → next-step: `npm audit` 수동 실행 권장")
    elif not audit_findings:
        lines.append("- 취약점 없음 [observed]")
    else:
        for f in audit_findings:
            icon = "🔴" if f["severity"] in ("critical", "high") else ("🟡" if f["severity"] == "moderate" else "🟢")
            lines.append(f"- {icon} `{f['pkg']}` ({f['severity']}): {f['title']} [observed]")
        if critical_vulns:
            lines += [
                "", "### ⚠ Critical/High 조치 권장",
                "- Unknown: 자동 업데이트 여부 (수동 확인 필요)",
                "  → next-step: `npm audit fix` 수동 실행 후 테스트",
                "  → NEVER: 자동 `npm install/update` (하네스 정책)"
            ]

lines += [
    "", "## Unknowns / Next Steps",
    "- 멀티-repo 집계: Unknown (현재 cwd 단독)",
    "  → next-step: CLAUDE_CODEX_AUTOMATIONS_REPOS 환경변수 추가 검토 (P1 완료 후)",
]
if audit_label != "observed" and "node" in stacks:
    lines.append(f"- npm audit 실패: Unknown → next-step: `npm audit` 수동 실행")

lines += [
    "", "## Scope-out",
    "- 본 리포트는 cwd 단일 프로젝트 기준.",
    "- NEVER: 자동 npm install / pip upgrade / go get (사용자 명시 승인만)",
    "",
    "---",
    f"_생성: {now_str} | 모드: {mode_label} | 비용: Codex API 호출 0건_",
]

# PostToolUse 모드 + 파일 이미 존재 → 감지 섹션 append
if OUTPUT_FILE.exists() and POSTTOOL_MODE:
    existing = OUTPUT_FILE.read_text(encoding="utf-8")
    # 같은 분 이내 중복 방지
    if f"PostToolUse 추가: {now_str[:16]}" in existing:
        sys.exit(0)
    append = (f"\n\n---\n_PostToolUse 추가: {now_str} — `{TRIGGER_FILE}` 변경 감지_")
    if critical_vulns:
        names = ", ".join(f["pkg"] for f in critical_vulns[:3])
        append += f"\n_🔴 Critical/High {len(critical_vulns)}건 ({names}) — `npm audit fix` 권장_"
    OUTPUT_FILE.write_text(existing + append + "\n", encoding="utf-8")
else:
    OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")

# statusMessage 출력 (PostToolUse + critical 시)
if POSTTOOL_MODE and critical_vulns:
    names = ", ".join(f["pkg"] for f in critical_vulns[:3])
    msg = f"⚠ Dep Drift: {len(critical_vulns)}건 critical/high ({names}) — dep-drift-{WEEK_TAG}.md"
    print(msg)
PYEOF
)

# statusMessage JSON 출력 (critical 취약점 즉시 알림)
if [ -n "$STATUS_INFO" ] && [ "$POSTTOOL_MODE" = "true" ]; then
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","statusMessage":"$STATUS_INFO"}}
EOF
fi

type obs_event >/dev/null 2>&1 && obs_event "codex-automations" "dep-drift-generated" \
  '{"mode":"'"$POSTTOOL_MODE"'","trigger":"'"$TRIGGER_FILE"'","week":"'"$WEEK_TAG"'","ts":"'$(date -Iseconds)'"}'

exit 0
