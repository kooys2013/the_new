#!/usr/bin/env bash
# 2604181802_lesson-reinforcer.sh — PostToolUse (Edit|Write|MultiEdit) Layer 3
# Daily Fit Loop 1-B: Edit/Write 발생 시 rules/ 및 accumulated-lessons.md 적중 감지 → [reinforced:YY/MM/DD] 태그 갱신.
# 원칙: <100ms (실측), silent exit 0, PostToolUse 체인 보호.

# Windows cp949 기본 인코딩 우회 — 한글 룰 파일 매칭 안정화
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

# HOOK_PAYLOAD: Claude Code가 PostToolUse 훅에 JSON 전달 (tool_input.file_path, tool_response 등)
HOOK_PAYLOAD=$(cat 2>/dev/null || true)
export HOOK_PAYLOAD

RULES_DIR="$HOME/.claude/rules"
LESSONS_FILE="$RULES_DIR/accumulated-lessons.md"
HARNESS_DIR="$HOME/.claude/_cache/harness"
mkdir -p "$HARNESS_DIR" 2>/dev/null || exit 0
REINFORCE_LOG="$HARNESS_DIR/reinforce-log.jsonl"

export RULES_DIR LESSONS_FILE REINFORCE_LOG

# Python heredoc — grep + 태그 갱신
timeout 2 python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, re, pathlib, datetime, sys

payload_raw = os.environ.get("HOOK_PAYLOAD", "")
rules_dir = pathlib.Path(os.environ.get("RULES_DIR", ""))
lessons_file = pathlib.Path(os.environ.get("LESSONS_FILE", ""))
reinforce_log = os.environ.get("REINFORCE_LOG", "")

# 1. file_path 추출
try:
    payload = json.loads(payload_raw) if payload_raw.strip() else {}
except Exception:
    payload = {}

tool_input = payload.get("tool_input") or {}
file_path = tool_input.get("file_path", "")

if not file_path:
    sys.exit(0)

# 2. 파일명 필터 — 관심 대상만
# 관심: .py/.ts/.tsx/.js/.jsx/.md/.yaml/.yml/.sh
interest = re.search(r"\.(py|ts|tsx|js|jsx|md|ya?ml|sh)$", file_path)
if not interest:
    sys.exit(0)

# 3. 파일명(stem) + 일반 키워드 추출
stem = pathlib.Path(file_path).stem.lower()
# 의미 있는 키워드 — stem이 너무 짧거나 범용이면 skip
if len(stem) < 4 or stem in {"test", "index", "main", "init", "utils", "types"}:
    sys.exit(0)

# 4. rules/ + lessons_file 내 키워드 grep — 적중 라인 찾기
today = datetime.date.today().strftime("%y/%m/%d")

# 정규식: [reinforced:YY/MM/DD] or [reinforced:YY/MM/DD,YY/MM/DD]
REINF_PATTERN = re.compile(r"\[reinforced:([^\]]+)\]")

updated_files = []
hits_count = 0

targets = []
if lessons_file.exists():
    targets.append(lessons_file)
if rules_dir.exists():
    targets.extend(sorted(rules_dir.glob("*.md")))

for target in targets:
    try:
        content = target.read_text(encoding="utf-8")
    except Exception:
        continue

    # 라인별 스캔
    new_lines = []
    changed = False
    for line in content.splitlines(keepends=True):
        if stem in line.lower() and REINF_PATTERN.search(line):
            # 이미 오늘자 기록되어 있으면 skip (중복 방지)
            m = REINF_PATTERN.search(line)
            if today not in m.group(1):
                # 기존 마지막 일자 뒤에 today 추가 (최대 3개 유지)
                dates = [d.strip() for d in m.group(1).split(",") if d.strip()]
                dates.append(today)
                dates = dates[-3:]  # 최근 3개만
                new_line = REINF_PATTERN.sub(f"[reinforced:{','.join(dates)}]", line, count=1)
                new_lines.append(new_line)
                changed = True
                hits_count += 1
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    if changed:
        try:
            target.write_text("".join(new_lines), encoding="utf-8")
            updated_files.append(str(target.name))
        except Exception:
            pass

# 5. 로그 기록 (적중 시만)
if hits_count > 0:
    try:
        rec = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "file_edited": file_path,
            "stem": stem,
            "hits": hits_count,
            "targets_updated": updated_files,
        }
        with open(reinforce_log, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except Exception:
        pass

    # 1000줄 초과 시 최근 500줄로 rotate
    try:
        p = pathlib.Path(reinforce_log)
        lines_all = p.read_text(encoding="utf-8").splitlines()
        if len(lines_all) > 1000:
            p.write_text("\n".join(lines_all[-500:]) + "\n", encoding="utf-8")
    except Exception:
        pass
PYEOF

exit 0
