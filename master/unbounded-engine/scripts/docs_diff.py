#!/usr/bin/env python3
"""
docs_diff.py — 스펙 문서 변경분 추출기

페이즈 1 이후 모든 페이즈에 자동 주입되어 스펙 드리프트 방어.
phase_runner.py가 자동 호출하지만, 수동 실행도 가능.
"""
import argparse
import subprocess
from pathlib import Path

DOCS_DIFF = Path(".oneshot/docs.diff")


def generate(spec_paths, ref="HEAD~1"):
    DOCS_DIFF.parent.mkdir(parents=True, exist_ok=True)
    diff = subprocess.check_output(
        ["git", "diff", ref, "--unified=0", "--"] + spec_paths,
        text=True,
        encoding="utf-8",
    )
    DOCS_DIFF.write_text(diff, encoding="utf-8")
    print(f"✅ {DOCS_DIFF} ({len(diff)} chars)")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--spec", nargs="+", required=True, help="스펙 파일 경로")
    p.add_argument("--ref", default="HEAD~1", help="diff 기준 (기본: HEAD~1)")
    args = p.parse_args()
    generate(args.spec, args.ref)


if __name__ == "__main__":
    main()
