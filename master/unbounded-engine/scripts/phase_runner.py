#!/usr/bin/env python3
"""
phase_runner.py — 헤드리스 Claude Code 페이즈 실행기

핵심 원리:
  - 각 페이즈를 `claude -p` subprocess로 독립 세션에서 실행
  - 메인 세션 컨텍스트 격리 → 의도 파악만 담당
  - progress.json 기반 체크포인트 복구
  - docs.diff 자동 주입 (스펙 드리프트 방어)
  - 페이즈마다 자동 git commit

사용법:
  # 신규 작업 시작
  python phase_runner.py init --task "feat: add X" --phases plan/phases.json

  # 실행 (중단 후 재개도 동일 명령)
  python phase_runner.py run

  # 상태 확인
  python phase_runner.py status

  # 강제 리셋 (해당 페이즈만)
  python phase_runner.py reset --phase 5
"""
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

KST = timezone(timedelta(hours=9))
PROGRESS_FILE = Path(".oneshot/progress.json")
DOCS_DIFF_FILE = Path(".oneshot/docs.diff")
PHASES_DIR = Path(".oneshot/phases")
LOGS_DIR = Path(".oneshot/logs")


def now_kst():
    return datetime.now(KST).isoformat()


def load_progress():
    if not PROGRESS_FILE.exists():
        return None
    return json.loads(PROGRESS_FILE.read_text(encoding="utf-8"))


def save_progress(progress):
    PROGRESS_FILE.parent.mkdir(parents=True, exist_ok=True)
    progress["updated_at"] = now_kst()
    PROGRESS_FILE.write_text(
        json.dumps(progress, ensure_ascii=False, indent=2), encoding="utf-8"
    )


def cmd_init(args):
    """progress.json 초기화 + 페이즈 파일 검증"""
    if PROGRESS_FILE.exists() and not args.force:
        print(f"⚠️  {PROGRESS_FILE} 이미 존재. --force로 덮어쓰기.")
        sys.exit(1)

    phases_spec = json.loads(Path(args.phases).read_text(encoding="utf-8"))
    PHASES_DIR.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    progress = {
        "task_name": args.task,
        "branch": _current_branch(),
        "created_at": now_kst(),
        "updated_at": now_kst(),
        "current_phase": 0,
        "total_phases": len(phases_spec["phases"]),
        "spec_files": phases_spec.get("spec_files", []),
        "phases": [
            {
                "id": i + 1,
                "name": p["name"],
                "status": "pending",
                "prompt_file": p["prompt_file"],
                "context_files": p.get("context_files", []),
                "expected_outputs": p.get("expected_outputs", []),
                "start_time": None,
                "end_time": None,
                "error": None,
                "commit_sha": None,
            }
            for i, p in enumerate(phases_spec["phases"])
        ],
    }
    save_progress(progress)
    print(f"✅ 초기화 완료 — {progress['total_phases']}개 페이즈")
    print(f"   다음: python phase_runner.py run")


def cmd_run(args):
    """페이즈 순차 실행 (재개 가능)"""
    progress = load_progress()
    if progress is None:
        print(f"❌ {PROGRESS_FILE} 없음. init 먼저.")
        sys.exit(1)

    while progress["current_phase"] < progress["total_phases"]:
        idx = progress["current_phase"]
        phase = progress["phases"][idx]

        if phase["status"] == "completed":
            progress["current_phase"] += 1
            continue

        print(f"\n{'='*60}")
        print(f"▶️  페이즈 {phase['id']}/{progress['total_phases']}: {phase['name']}")
        print(f"{'='*60}")

        phase["status"] = "running"
        phase["start_time"] = now_kst()
        save_progress(progress)

        try:
            _run_phase(phase, progress)
            phase["status"] = "completed"
            phase["end_time"] = now_kst()
            phase["commit_sha"] = _git_commit(phase)
            progress["current_phase"] += 1
            save_progress(progress)
            print(f"✅ 페이즈 {phase['id']} 완료 (commit: {phase['commit_sha'][:7]})")
        except Exception as e:
            phase["status"] = "failed"
            phase["end_time"] = now_kst()
            phase["error"] = str(e)
            save_progress(progress)
            print(f"❌ 페이즈 {phase['id']} 실패: {e}")
            print(f"   재시도: python phase_runner.py run")
            print(f"   리셋: python phase_runner.py reset --phase {phase['id']}")
            sys.exit(2)

    print(f"\n🎉 전체 페이즈 {progress['total_phases']}개 완료")
    _final_summary(progress)


def _run_phase(phase, progress):
    """단일 페이즈를 헤드리스 claude -p 로 실행"""
    prompt_path = PHASES_DIR / phase["prompt_file"]
    if not prompt_path.exists():
        raise FileNotFoundError(f"페이즈 프롬프트 없음: {prompt_path}")

    # 1) 프롬프트 본문 로드
    prompt = prompt_path.read_text(encoding="utf-8")

    # 2) docs.diff 주입 (페이즈 1 이후부터)
    if phase["id"] > 1 and DOCS_DIFF_FILE.exists():
        docs_diff = DOCS_DIFF_FILE.read_text(encoding="utf-8")
        prompt = (
            "## 📋 직전까지의 스펙 문서 변경분 (반드시 반영)\n\n"
            f"```\n{docs_diff}\n```\n\n"
            "---\n\n"
            f"{prompt}"
        )

    # 3) 컨텍스트 파일 주입
    context_blocks = []
    for cf in phase.get("context_files", []):
        if Path(cf).exists():
            context_blocks.append(f"### {cf}\n```\n{Path(cf).read_text(encoding='utf-8')[:8000]}\n```")
    if context_blocks:
        prompt = "\n\n".join(context_blocks) + "\n\n---\n\n" + prompt

    # 4) 헤드리스 실행
    log_file = LOGS_DIR / f"phase_{phase['id']:02d}_{datetime.now(KST).strftime('%Y%m%d_%H%M%S')}.log"

    print(f"   📝 프롬프트 길이: {len(prompt)} chars")
    print(f"   📂 로그: {log_file}")

    result = subprocess.run(
        ["claude", "-p", "--dangerously-skip-permissions"],
        input=prompt,
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=3600,  # 페이즈당 최대 1시간
    )

    # 5) 로그 저장
    log_file.write_text(
        f"=== STDOUT ===\n{result.stdout}\n\n=== STDERR ===\n{result.stderr}",
        encoding="utf-8",
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"claude -p 종료 코드 {result.returncode}\n"
            f"STDERR: {result.stderr[:500]}"
        )

    # 6) 페이즈 1 직후에는 docs.diff 자동 생성
    if phase["id"] == 1:
        spec_files = progress.get("spec_files", [])
        if spec_files:
            _generate_docs_diff(spec_files)


def _generate_docs_diff(spec_files):
    """페이즈 1 (문서 업데이트) 직후 git diff로 docs.diff 생성"""
    try:
        diff = subprocess.check_output(
            ["git", "diff", "HEAD", "--unified=0", "--"] + spec_files,
            text=True,
            encoding="utf-8",
        )
        DOCS_DIFF_FILE.write_text(diff, encoding="utf-8")
        print(f"   📑 docs.diff 생성 ({len(diff)} chars)")
    except subprocess.CalledProcessError as e:
        print(f"   ⚠️  docs.diff 생성 실패: {e}")


def _git_commit(phase):
    """페이즈 완료 시 자동 커밋"""
    subprocess.run(["git", "add", "-A"], check=True)
    result = subprocess.run(
        ["git", "diff", "--cached", "--quiet"], capture_output=True
    )
    if result.returncode == 0:
        return _git_head_sha()

    msg = (
        f"feat(phase-{phase['id']:02d}): {phase['name']}\n\n"
        f"Phase: {phase['id']}\n"
        f"Started: {phase['start_time']}\n"
        f"Ended: {phase['end_time']}\n\n"
        f"Generated by phase_runner.py (oneshot-dev v2)"
    )
    subprocess.run(["git", "commit", "-m", msg], check=True)
    return _git_head_sha()


def _git_head_sha():
    return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()


def _current_branch():
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
        ).strip()
    except Exception:
        return "unknown"


def cmd_status(args):
    progress = load_progress()
    if progress is None:
        print("❌ progress.json 없음")
        return

    print(f"📋 작업: {progress['task_name']}")
    print(f"🌿 브랜치: {progress['branch']}")
    print(f"📅 시작: {progress['created_at']}")
    print(f"🔄 갱신: {progress['updated_at']}")
    print(f"📊 진행: {progress['current_phase']}/{progress['total_phases']}\n")

    icon = {"pending": "⏳", "running": "🔄", "completed": "✅", "failed": "❌"}
    for p in progress["phases"]:
        sha = f"({p['commit_sha'][:7]})" if p.get("commit_sha") else ""
        print(f"  {icon.get(p['status'], '?')} {p['id']:02d}. {p['name']} {sha}")
        if p["status"] == "failed":
            print(f"      ⚠️  {p['error']}")


def cmd_reset(args):
    """특정 페이즈 상태를 pending으로 되돌림 (재실행 가능)"""
    progress = load_progress()
    if progress is None:
        sys.exit(1)

    target = args.phase
    for p in progress["phases"]:
        if p["id"] == target:
            p["status"] = "pending"
            p["start_time"] = None
            p["end_time"] = None
            p["error"] = None
            p["commit_sha"] = None
            progress["current_phase"] = target - 1
            save_progress(progress)
            print(f"♻️  페이즈 {target} 리셋 완료. run 재실행 가능.")
            return

    print(f"❌ 페이즈 {target} 없음")
    sys.exit(1)


def _final_summary(progress):
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    summary = LOGS_DIR / f"summary_{datetime.now(KST).strftime('%Y%m%d_%H%M%S')}.md"
    lines = [
        f"# {progress['task_name']} — 완료 요약",
        f"",
        f"- 브랜치: `{progress['branch']}`",
        f"- 시작: {progress['created_at']}",
        f"- 종료: {progress['updated_at']}",
        f"- 페이즈: {progress['total_phases']}개",
        f"",
        f"## 페이즈 결과",
        f"",
    ]
    for p in progress["phases"]:
        lines.append(
            f"- ✅ {p['id']:02d}. {p['name']} — `{p.get('commit_sha', '?')[:7]}`"
        )
    summary.write_text("\n".join(lines), encoding="utf-8")
    print(f"📄 요약: {summary}")


def main():
    parser = argparse.ArgumentParser(prog="phase_runner")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="progress.json 초기화")
    p_init.add_argument("--task", required=True, help="작업 이름")
    p_init.add_argument("--phases", required=True, help="phases.json 경로")
    p_init.add_argument("--force", action="store_true")

    sub.add_parser("run", help="페이즈 실행 (재개 가능)")
    sub.add_parser("status", help="현재 진행 상황")

    p_reset = sub.add_parser("reset", help="특정 페이즈 재실행 가능 상태로")
    p_reset.add_argument("--phase", type=int, required=True)

    args = parser.parse_args()
    {"init": cmd_init, "run": cmd_run, "status": cmd_status, "reset": cmd_reset}[
        args.cmd
    ](args)


if __name__ == "__main__":
    main()
