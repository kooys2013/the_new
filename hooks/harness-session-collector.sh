#!/usr/bin/env bash
# harness-session-collector.sh — Stop 훅
# 세션 종료 시 사용 데이터를 _cache/harness/sessions.jsonl에 누적
# 수집: 스킬 호출 목록 / hook 이벤트 수 / session 품질 신호
# 원칙: <1s, silent exit 0

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || exit 0
obs_init

HARNESS_DIR="$HOME/.claude/_cache/harness"
mkdir -p "$HARNESS_DIR" 2>/dev/null || exit 0

export HARNESS_DIR
# PROJECT_DIR: 현재 작업 디렉토리 기반 프로젝트 ID 계산 (Claude Code 규칙)
export PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$HOME/.claude/projects}"

python3 - 2>/dev/null <<'PYEOF' || exit 0
import json, os, re, pathlib, datetime, glob

harness_dir = pathlib.Path(os.environ.get("HARNESS_DIR", ""))
project_dir = pathlib.Path(os.environ.get("PROJECT_DIR", pathlib.Path.home() / ".claude" / "projects"))
sessions_file = harness_dir / "sessions.jsonl"

now = datetime.datetime.now()

skills_this_session = {}
has_edit = False
has_verification = False

# ── 가장 최근에 수정된 프로젝트 JSONL에서 tool call 추출 ──
try:
    all_jsonls = sorted(
        glob.glob(str(project_dir / "**" / "*.jsonl"), recursive=True),
        key=os.path.getmtime,
    )
    # agent-* 파일 제외, 가장 최근 세션 파일
    session_files = [f for f in all_jsonls if "/agent-" not in f.replace("\\", "/")]
    if session_files:
        latest = session_files[-1]
        with open(latest, encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()[-500:]

        for line in lines:
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
            except Exception:
                continue

            # assistant 메시지의 tool_use 블록 파싱
            msg = obj.get("message", {})
            if isinstance(msg, dict) and msg.get("role") == "assistant":
                for block in msg.get("content", []):
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "tool_use":
                        tool_name = block.get("name", "")
                        inp = block.get("input", {})
                        # Skill 도구 호출 감지
                        if tool_name == "Skill":
                            sk = inp.get("skill", "")
                            if sk:
                                skills_this_session[sk] = skills_this_session.get(sk, 0) + 1
                        # Edit/Write/MultiEdit 도구 사용
                        if tool_name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
                            has_edit = True
                        # 검증 관련 도구
                        if tool_name == "Bash":
                            cmd = str(inp.get("command", "")).lower()
                            if any(k in cmd for k in ("pytest", "test", "verify", "drift-sentinel")):
                                has_verification = True
except Exception:
    pass

# ── 품질 점수 간이 산출 ──
skill_count = sum(skills_this_session.values())
unique_skills = len(skills_this_session)

# 세션 품질 신호 (0-100)
quality = 0
quality += min(40, skill_count * 8)         # 스킬 사용 (5회 = 40점)
quality += min(20, unique_skills * 7)        # 스킬 다양성 (3종 = 20점)
quality += 20 if has_edit else 0             # 실제 작업 수행
quality += 20 if has_verification else 0     # 검증 수행

record = {
    "ts": now.isoformat(),
    "date": now.strftime("%Y-%m-%d"),
    "skill_count": skill_count,
    "unique_skills": unique_skills,
    "skills": list(skills_this_session.keys()),
    "has_edit": has_edit,
    "has_verification": has_verification,
    "quality_score": min(100, quality),
}

# sessions.jsonl append
with open(sessions_file, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, ensure_ascii=False) + "\n")

# 1000줄 초과 시 최근 500줄로 rotate
try:
    lines_all = sessions_file.read_text(encoding="utf-8").splitlines()
    if len(lines_all) > 1000:
        sessions_file.write_text("\n".join(lines_all[-500:]) + "\n", encoding="utf-8")
except Exception:
    pass
PYEOF

exit 0
