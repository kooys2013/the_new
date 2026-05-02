#!/usr/bin/env bash
# codex-daily-activity.sh — 일일 Standup 자동 집계 (카테고리 A)
# 트리거: Task Scheduler 09:00 daily / 수동 실행
# 입력: git log + _cache/codex-bg + _cache/obs (모두 누적된 로컬 데이터, Codex API 호출 0)
# 출력: _cache/codex-automations/standup-YYMMDD.md (Evidence Rules 준수)
# 원칙: <30s, silent exit 0, write 0건 (보고서만 생성)

export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/_lib/obs.sh" 2>/dev/null || true
type obs_init >/dev/null 2>&1 && obs_init

OUTPUT_DIR="$HOME/.claude/_cache/codex-automations"
OBS_DIR="$HOME/.claude/_cache/obs"
CODEX_BG_DIR="$HOME/.claude/_cache/codex-bg"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || exit 0

TODAY=$(date +%y%m%d)
YESTERDAY=$(date -d "yesterday" +%y%m%d 2>/dev/null || date -v-1d +%y%m%d 2>/dev/null || echo "")
OUTPUT_FILE="$OUTPUT_DIR/standup-${TODAY}.md"

# 이미 오늘 생성됨 → skip (중복 방지)
if [ -f "$OUTPUT_FILE" ]; then
    type obs_event >/dev/null 2>&1 && obs_event "codex-automations" "standup-skip" '{"reason":"already_exists","ts":"'$(date -Iseconds)'"}'
    exit 0
fi

export OUTPUT_FILE OBS_DIR CODEX_BG_DIR TODAY YESTERDAY

timeout 25 python3 - 2>/dev/null <<'PYEOF' || exit 0
import os, json, pathlib, datetime, glob, subprocess, re

OUT = os.environ["OUTPUT_FILE"]
OBS_DIR = pathlib.Path(os.environ["OBS_DIR"])
CODEX_BG = pathlib.Path(os.environ["CODEX_BG_DIR"])
TODAY = os.environ["TODAY"]
YESTERDAY = os.environ.get("YESTERDAY", "")

now = datetime.datetime.now()
yest = now - datetime.timedelta(days=1)
yest_iso = yest.strftime("%Y-%m-%d")

# --- 1. git commits (어제) — 활성 프로젝트 다수 가능, cwd 단독 ---
commits = []
try:
    cwd = os.getcwd()
    res = subprocess.run(
        ["git", "log", f"--since={yest_iso} 00:00", f"--until={yest_iso} 23:59",
         "--pretty=format:%h|%s|%an"],
        capture_output=True, text=True, timeout=5, cwd=cwd
    )
    if res.returncode == 0 and res.stdout.strip():
        for line in res.stdout.strip().split("\n")[:20]:
            parts = line.split("|", 2)
            if len(parts) == 3:
                commits.append({"sha": parts[0], "msg": parts[1], "author": parts[2]})
except Exception:
    pass

# --- 2. Codex bg 결과 (어제 mtime) ---
codex_results = []
if CODEX_BG.exists():
    cutoff = (yest.replace(hour=0, minute=0, second=0)).timestamp()
    cutoff_end = (yest.replace(hour=23, minute=59, second=59)).timestamp()
    for f in sorted(CODEX_BG.glob("*.txt"), key=lambda p: p.stat().st_mtime, reverse=True)[:10]:
        try:
            mt = f.stat().st_mtime
            if cutoff <= mt <= cutoff_end:
                codex_results.append({
                    "file": f.name,
                    "ts": datetime.datetime.fromtimestamp(mt).isoformat(timespec="seconds"),
                    "size": f.stat().st_size,
                })
        except Exception:
            continue

# --- 3. obs.jsonl 어제 이벤트 통계 ---
iso_yr, iso_wk, _ = yest.isocalendar()
obs_file = OBS_DIR / f"{iso_yr}-{iso_wk:02d}.jsonl"
event_counts = {}
skill_calls = {}
total_events = 0
if obs_file.exists():
    yest_date_str = yest.strftime("%Y-%m-%d")
    try:
        with open(obs_file, encoding="utf-8") as f:
            for line in f:
                try:
                    e = json.loads(line)
                    ts = e.get("ts", "")
                    if not ts.startswith(yest_date_str):
                        continue
                    total_events += 1
                    ev = e.get("event", "?")
                    event_counts[ev] = event_counts.get(ev, 0) + 1
                    if ev in ("skill-call", "skill_call"):
                        sk = e.get("skill") or e.get("data", {}).get("skill", "?")
                        skill_calls[sk] = skill_calls.get(sk, 0) + 1
                except Exception:
                    continue
    except Exception:
        pass

# --- 보고서 생성 (Evidence Rules 매크로 준수) ---
lines = []
lines.append(f"# Daily Standup — {TODAY}")
lines.append("")
lines.append("> Evidence Rules (E1-E6) 준수.")
lines.append("> 인용: `commit:abc1234` / `obs.jsonl[ts]` / `codex-bg/{file}`")
lines.append("> 라벨: `[observed]` 직접 측정 / `[suspected]` 간접 추론 / `[inferred]` 논리 도출")
lines.append("")
lines.append("## Summary")
lines.append(f"- 어제({yest_iso}) 커밋: **{len(commits)}건** [observed]")
lines.append(f"- 어제 Codex bg 결과: **{len(codex_results)}건** [observed]")
lines.append(f"- 어제 obs 이벤트: **{total_events}건** [observed] (인용: `{obs_file.name}`)")
lines.append("")

# Yesterday's commits
lines.append("## Yesterday (어제 작업)")
if commits:
    for c in commits:
        lines.append(f"- `commit:{c['sha']}` {c['msg']} _(by {c['author']})_ [observed]")
else:
    lines.append("- Unknown (cwd `git log` 결과 없음)")
    lines.append("  → next-step: 다른 프로젝트 디렉토리에서 수동 실행 또는 멀티 repo 집계 훅 확장 검토")
lines.append("")

# Codex bg results
lines.append("## Codex Background Results")
if codex_results:
    for r in codex_results:
        lines.append(f"- `codex-bg/{r['file']}` ({r['size']}B, {r['ts']}) [observed]")
else:
    lines.append("- no measurements found (어제 Codex bg 누적 0건)")
    lines.append("  → next-step: `/codex:review --background` 활용 권장 (쿼터 GREEN 시)")
lines.append("")

# Skill usage stats
lines.append("## Skill Usage (어제)")
if skill_calls:
    top = sorted(skill_calls.items(), key=lambda kv: -kv[1])[:10]
    for sk, n in top:
        lines.append(f"- `{sk}`: {n}회 [observed] (인용: `{obs_file.name}`)")
elif total_events > 0:
    lines.append(f"- skill-call 이벤트 없음, 다른 이벤트 {total_events}건 (인용: `{obs_file.name}`) [observed]")
    top_ev = sorted(event_counts.items(), key=lambda kv: -kv[1])[:5]
    for ev, n in top_ev:
        lines.append(f"  - `{ev}`: {n}회")
else:
    lines.append("- no measurements found (어제 obs 이벤트 0)")
    lines.append("  → next-step: SessionStart 훅 정상 동작 여부 점검")
lines.append("")

# Today's focus (inferred from yesterday + WIP)
lines.append("## Today (오늘 권장 포커스)")
lines.append("- [inferred] 어제 미완 항목 우선 점검 (위 commits 기반)")
lines.append("- [inferred] Codex 쿼터 GREEN 시 `/codex:review` 1회 권장")
lines.append("")

# Unknowns / scope-out
lines.append("## Unknowns / Next Steps")
lines.append("- multi-repo 활동 집계: Unknown (현재 cwd 단독)")
lines.append("  → next-step: register-codex-automations.sh에 활성 프로젝트 목록 환경변수 추가")
lines.append("")
lines.append("## Scope-out")
lines.append(f"- 본 보고서는 어제({yest_iso}) 데이터만 집계. 실시간 진행 작업은 별도 statusline 참조.")
lines.append("")
lines.append("---")
lines.append(f"_생성: {now.isoformat(timespec='seconds')} | 비용: Codex API 호출 0건_")

pathlib.Path(OUT).write_text("\n".join(lines), encoding="utf-8")
print(f"OK standup-{TODAY}.md")
PYEOF

# obs 이벤트 기록
if [ -f "$OUTPUT_FILE" ]; then
    type obs_event >/dev/null 2>&1 && \
      obs_event "codex-automations" "standup-generated" \
        '{"file":"standup-'"$TODAY"'.md","ts":"'$(date -Iseconds)'"}' || true
fi

exit 0
