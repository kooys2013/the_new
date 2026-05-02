#!/usr/bin/env bash
# Z-1 7일 의례 — 7일 평가 보고서 자동 산출
# 이벤트: cron 2026-05-08 13:00 / SLA: ≤30s
# 출력: _report/2605081300_7day-validation.md
# silent exit 0

set -u
exec 2>/dev/null

CLAUDE_DIR="${HOME}/.claude"
STATE_DIR="${CLAUDE_DIR}/_state"
REPORT_DIR="${CLAUDE_DIR}/_report"
ARCHIVE_DIR="${CLAUDE_DIR}/_archive"
BASELINE="${STATE_DIR}/baseline-2605011250.json"
OUT="${REPORT_DIR}/2605081300_7day-validation.md"

[ -f "${BASELINE}" ] || exit 0
mkdir -p "${REPORT_DIR}" 2>/dev/null

# Windows python 호환 path 변환 (Git Bash 환경)
STATE_WIN=$(cygpath -w "${STATE_DIR}" 2>/dev/null || echo "${STATE_DIR}")
BASELINE_WIN=$(cygpath -w "${BASELINE}" 2>/dev/null || echo "${BASELINE}")
export STATE_WIN BASELINE_WIN
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

python3 - <<'PY' >"${OUT}" 2>/dev/null
import json, os, glob, sys
from pathlib import Path

state = Path(os.environ.get("STATE_WIN") or (Path.home() / ".claude" / "_state"))
baseline_path = Path(os.environ.get("BASELINE_WIN") or (state / "baseline-2605011250.json"))
try:
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
except Exception:
    sys.exit(0)

# 7일 스냅샷 집계
snaps = sorted(glob.glob(str(state / "usage-day-*.json")))
totals = {"skills": {}, "hooks": {}}
days_covered = []
for p in snaps:
    try:
        d = json.loads(Path(p).read_text(encoding="utf-8"))
    except Exception:
        continue
    days_covered.append(d.get("day", Path(p).stem))
    for k, v in (d.get("skills") or {}).items():
        totals["skills"][k] = totals["skills"].get(k, 0) + int(v or 0)
    for k, v in (d.get("hooks") or {}).items():
        totals["hooks"][k] = totals["hooks"].get(k, 0) + int(v or 0)

def classify(n):
    if n == 0: return "ghost"
    if n == 1: return "underverified"
    if n <= 3: return "in-progress"
    return "verified"

def bucket(items):
    out = {"ghost": [], "underverified": [], "in-progress": [], "verified": []}
    for name, n in sorted(items.items()):
        out[classify(n)].append((name, n))
    return out

skill_b = bucket(totals["skills"])
hook_b = bucket(totals["hooks"])
all_assets = list(totals["skills"].items()) + list(totals["hooks"].items())
total_n = len(all_assets)
verified_n = len(skill_b["verified"]) + len(hook_b["verified"])
verified_pct = (verified_n / total_n * 100) if total_n else 0.0

print("# 7-Day Validation Report — Z-1 의례")
print()
print(f"- baseline: `baseline-2605011250.json`")
print(f"- 시작: {baseline.get('start_ts')}")
print(f"- 종료: {baseline.get('end_ts')}")
print(f"- 일일 스냅샷 수집: {len(snaps)}일분 ({', '.join(days_covered) or 'none'})")
print(f"- 자평: {baseline.get('v2_1_self_claim')}")
print(f"- 실증 검증됨 비율: **{verified_n}/{total_n} = {verified_pct:.1f}%**")
print()
print("## §1 자평 vs 실증 매트릭스")
print()
print("| 자산 | 7일 호출 | 분류 |")
print("|---|---:|---|")
for kind, b in [("skill", skill_b), ("hook", hook_b)]:
    for tier in ["verified","in-progress","underverified","ghost"]:
        for name, n in b[tier]:
            print(f"| {kind}: `{name}` | {n} | {tier} |")
print()
print("## §2 유령 자산 리스트 (7일 0회) → archive 큐")
ghosts = skill_b["ghost"] + hook_b["ghost"]
if ghosts:
    for name, _ in ghosts:
        print(f"- [ ] `{name}` → `_archive/ghost-assets-2605081300/`")
else:
    print("- (없음)")
print()
print("## §3 검증 부족 자산 (7일 1~3회) → 30일 연장")
under = skill_b["underverified"] + skill_b["in-progress"] + hook_b["underverified"] + hook_b["in-progress"]
if under:
    for name, n in under:
        print(f"- `{name}` ({n}회) → 30일 의례 승계")
else:
    print("- (없음)")
print()
print("## §4 검증됨 자산 (7일 4회+)")
ver = skill_b["verified"] + hook_b["verified"]
if ver:
    for name, n in ver:
        print(f"- `{name}` ({n}회) ✅ 데이터 입증")
else:
    print("- (없음)")
print()
print("## §5 다음 액션")
print("- [ ] 유령 자산 archive 사용자 승인")
print("- [ ] 30일 연장 의례 자동 승계 (baseline-2605081300)")
gate = "v2.2 부분 작성 가능 (검증된 항목만)" if verified_pct >= 50 else "v2.2 작성 보류 → 30일 의례 강제"
print(f"- [ ] v2.2 게이트 판정: **{gate}**")
print()
print("---")
print(f"_자동 생성: 2605011251_7day-evaluation.sh / 자평 100% / 실증 {verified_pct:.1f}%_")
PY

exit 0
