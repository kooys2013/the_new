#!/usr/bin/env bash
# apply-daily-fit.sh — Daily Fit DNA Mutation 수동 승인 CLI
# Usage:
#   apply-daily-fit.sh                     # 오늘 제안 목록 출력
#   apply-daily-fit.sh P <파일경로>          # Promote (archive/ 승격 또는 상위 티어 승격)
#   apply-daily-fit.sh D <파일경로>          # Demote (dormant 표기 추가)
#   apply-daily-fit.sh R <파일경로>          # Reevaluate (conflict 주석 + 수동 리뷰 대기)
#   apply-daily-fit.sh A <파일경로>          # Activate (archive/에서 원위치 복귀 or dormant 주석 제거)
#
# 원칙: 자동 변이 금지 — 사용자가 P/D/R/A 명시적으로 지정해야 실행.

set -euo pipefail

# Windows cp949 기본 인코딩 우회 — 이모지/한글 출력 안정화
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

source "$(dirname "$0")/../_lib/obs.sh" 2>/dev/null || {
    echo "ERROR: _lib/obs.sh 로드 실패" >&2
    exit 1
}
obs_init

HARNESS_DIR="$HOME/.claude/_cache/harness"
CLAUDE_HOME="$HOME/.claude"
ARCHIVE_DIR="$CLAUDE_HOME/archive"
TODAY=$(date +%y%m%d)
MUTATION_FILE="$HARNESS_DIR/mutation-${TODAY}.json"

mkdir -p "$ARCHIVE_DIR" 2>/dev/null || true

# ── 인자 없음: 오늘 제안 목록 출력 ──
if [ $# -eq 0 ]; then
    echo "┌─── Daily Fit DNA Mutation 제안 (${TODAY}) ───────────────────┐"
    if [ ! -f "$MUTATION_FILE" ]; then
        echo "│ 오늘자 제안 없음. Layer 2 analyzer를 먼저 실행하세요:"
        echo "│   bash ~/.claude/hooks/2604181801_daily-fit-analyzer.sh"
        echo "└──────────────────────────────────────────────────────────────┘"
        exit 0
    fi

    export MUTATION_FILE
    python3 - <<'PYEOF'
import json, os, sys
mfile = os.environ["MUTATION_FILE"]
try:
    with open(mfile, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"│ 로드 실패: {e}")
    sys.exit(0)

pick = data.get("pick")
if pick:
    print(f"│ 🥇 PICK: [{pick['code']}] {pick['target']}")
    print(f"│   사유: {pick.get('reason', '-')}")
    print(f"│   승인: bash ~/.claude/hooks/_setup/apply-daily-fit.sh {pick['code']} {pick['target']}")
else:
    print("│ PICK 없음 (모든 자산 안정 또는 임계값 미충족)")

print("│")
print("│ TOP 5 후보:")
for i, c in enumerate(data.get("candidates", [])[:5], 1):
    print(f"│   {i}. [{c['code']}] {c['target']} — {c.get('reason', '-')} (score={c.get('score', 0):.1f})")

print("└──────────────────────────────────────────────────────────────┘")
print()
print("사용법:")
print("  apply-daily-fit.sh P <경로>  # Promote")
print("  apply-daily-fit.sh D <경로>  # Demote")
print("  apply-daily-fit.sh R <경로>  # Reevaluate")
print("  apply-daily-fit.sh A <경로>  # Activate")
PYEOF
    exit 0
fi

# ── 인자 2개 검증 ──
if [ $# -lt 2 ]; then
    echo "ERROR: 인자가 부족합니다. Usage: apply-daily-fit.sh P|D|R|A <파일경로>" >&2
    exit 1
fi

CODE="$1"
TARGET_RAW="$2"

# 파일경로 정규화 — ~/.claude 기준 상대경로 또는 절대경로 허용
if [[ "$TARGET_RAW" = /* ]] || [[ "$TARGET_RAW" =~ ^[A-Z]:[/\\] ]]; then
    TARGET_ABS="$TARGET_RAW"
else
    TARGET_ABS="$CLAUDE_HOME/$TARGET_RAW"
fi

# Git Bash → Windows 경로 변환 (Python 네이티브 바이너리가 /c/... 를 못 읽음)
# 쉘 단에서는 TARGET_ABS (MSYS) 유지, Python에 넘길 때만 TARGET_ABS_WIN 사용
if command -v cygpath >/dev/null 2>&1 && [[ "$TARGET_ABS" = /* ]]; then
    TARGET_ABS_WIN=$(cygpath -w "$TARGET_ABS" 2>/dev/null || echo "$TARGET_ABS")
else
    TARGET_ABS_WIN="$TARGET_ABS"
fi

# ── 후보 검증 — mutation-YYMMDD.json에 존재하는 타겟이어야 함 ──
if [ ! -f "$MUTATION_FILE" ]; then
    echo "ERROR: 오늘자 제안 파일 없음 ($MUTATION_FILE). Layer 2 먼저 실행하세요." >&2
    exit 2
fi

export MUTATION_FILE TARGET_RAW CODE
VALID=$(python3 - <<'PYEOF'
import json, os
mfile = os.environ["MUTATION_FILE"]
target = os.environ["TARGET_RAW"]
code = os.environ["CODE"]

try:
    with open(mfile, encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    print("0")
    exit(0)

# pick 또는 candidates 중에 매칭
match = False
all_cands = [data.get("pick")] + data.get("candidates", [])
for c in all_cands:
    if not c:
        continue
    if c.get("code") == code and c.get("target") == target:
        match = True
        break

print("1" if match else "0")
PYEOF
)

if [ "$VALID" != "1" ]; then
    echo "ERROR: [$CODE] $TARGET_RAW 는 오늘자 제안 후보에 없습니다." >&2
    echo "       오늘 제안 확인: apply-daily-fit.sh" >&2
    exit 3
fi

# ── 파일 존재 확인 ──
if [ ! -e "$TARGET_ABS" ] && [ "$CODE" != "A" ]; then
    echo "ERROR: 파일 없음: $TARGET_ABS" >&2
    exit 4
fi

# ── 코드별 실행 ──
NOW=$(date +%y/%m/%d)
BACKUP_DIR="$HARNESS_DIR/apply-backup-${TODAY}"
mkdir -p "$BACKUP_DIR" 2>/dev/null || true

case "$CODE" in
    P)
        # Promote — candidate-archive의 경우 archive/로 이동, candidate-promote는 상위 티어 표기 추가
        echo "[P] Promote: $TARGET_RAW"
        # 백업
        cp -p "$TARGET_ABS" "$BACKUP_DIR/$(basename "$TARGET_ABS")" 2>/dev/null || true

        # 분기: archive 승격 or 티어 승격
        # candidate-promote 판정: 파일 내 [reinforced:] 3회 이상이면 tier up (헤더 주석만 추가)
        REINF_COUNT=$(grep -oE '\[reinforced:[^\]]+\]' "$TARGET_ABS" 2>/dev/null | head -1 | grep -oE '[0-9]{2}/[0-9]{2}/[0-9]{2}' | wc -l)
        if [ "${REINF_COUNT:-0}" -ge 3 ]; then
            # 티어 승격 — 헤더에 주석 추가
            if ! head -5 "$TARGET_ABS" | grep -q "promoted:"; then
                python3 - "$TARGET_ABS_WIN" "$NOW" <<'PYEOF'
import sys
p, now = sys.argv[1:3]
with open(p, encoding="utf-8") as f:
    content = f.read()
# 첫 줄에 주석 추가
header = f"<!-- promoted:{now} reason=reinforced-threshold -->\n"
with open(p, "w", encoding="utf-8") as f:
    f.write(header + content)
PYEOF
            fi
            echo "  → 티어 승격 완료 (헤더에 promoted:$NOW 태그 추가)"
        else
            # archive/로 이동
            REL_PATH="${TARGET_ABS#$CLAUDE_HOME/}"
            DEST="$ARCHIVE_DIR/$REL_PATH"
            mkdir -p "$(dirname "$DEST")" 2>/dev/null || true
            mv "$TARGET_ABS" "$DEST"
            echo "  → archive/$REL_PATH 로 이동"
        fi
        ;;

    D)
        # Demote — dormant 주석 추가 (파일 상단)
        echo "[D] Demote: $TARGET_RAW"
        cp -p "$TARGET_ABS" "$BACKUP_DIR/$(basename "$TARGET_ABS")" 2>/dev/null || true
        if ! head -5 "$TARGET_ABS" | grep -q "dormant:"; then
            python3 - "$TARGET_ABS_WIN" "$NOW" <<'PYEOF'
import sys
p, now = sys.argv[1:3]
with open(p, encoding="utf-8") as f:
    content = f.read()
header = f"<!-- dormant:{now} reason=low-hit-rate -->\n"
with open(p, "w", encoding="utf-8") as f:
    f.write(header + content)
PYEOF
            echo "  → dormant:$NOW 태그 추가"
        else
            echo "  → 이미 dormant 태그 존재 (no-op)"
        fi
        ;;

    R)
        # Reevaluate — conflict 주석 + TODO
        echo "[R] Reevaluate: $TARGET_RAW"
        cp -p "$TARGET_ABS" "$BACKUP_DIR/$(basename "$TARGET_ABS")" 2>/dev/null || true
        python3 - "$TARGET_ABS_WIN" "$NOW" <<'PYEOF'
import sys
p, now = sys.argv[1:3]
with open(p, encoding="utf-8") as f:
    content = f.read()
note = f"\n\n<!-- REEVALUATE {now}: conflict/drop detected by daily-fit-analyzer — 수동 리뷰 필요 -->\n"
with open(p, "a", encoding="utf-8") as f:
    f.write(note)
PYEOF
        echo "  → 파일 말미에 REEVALUATE:$NOW 주석 추가 — 수동 리뷰 대기"
        ;;

    A)
        # Activate — archive/에서 원위치 복귀 or dormant 주석 제거
        echo "[A] Activate: $TARGET_RAW"
        REL_PATH="${TARGET_ABS#$CLAUDE_HOME/}"
        ARCHIVED="$ARCHIVE_DIR/$REL_PATH"

        if [ -e "$ARCHIVED" ] && [ ! -e "$TARGET_ABS" ]; then
            # archive에서 복귀
            mkdir -p "$(dirname "$TARGET_ABS")" 2>/dev/null || true
            mv "$ARCHIVED" "$TARGET_ABS"
            echo "  → archive/에서 원위치 복귀"
        elif [ -e "$TARGET_ABS" ]; then
            # dormant 태그 제거
            cp -p "$TARGET_ABS" "$BACKUP_DIR/$(basename "$TARGET_ABS")" 2>/dev/null || true
            python3 - "$TARGET_ABS_WIN" "$NOW" <<'PYEOF'
import sys, re
p, now = sys.argv[1:3]
with open(p, encoding="utf-8") as f:
    content = f.read()
content_new = re.sub(r"<!-- dormant:[^>]+ -->\n", "", content)
content_new = f"<!-- resurrected:{now} -->\n" + content_new
with open(p, "w", encoding="utf-8") as f:
    f.write(content_new)
PYEOF
            echo "  → dormant 태그 제거 + resurrected:$NOW 추가"
        else
            echo "ERROR: 파일이 없고 archive에도 없음: $TARGET_ABS" >&2
            exit 5
        fi
        ;;

    *)
        echo "ERROR: 알 수 없는 코드 '$CODE'. 사용: P|D|R|A" >&2
        exit 1
        ;;
esac

# ── obs 이벤트 기록 ──
obs_append dna-mutation info "{\"code\":\"$CODE\",\"target\":\"$TARGET_RAW\",\"date\":\"$NOW\"}" 2>/dev/null || true

# ── apply 로그 ──
APPLY_LOG="$HARNESS_DIR/apply-log.jsonl"
python3 - <<PYEOF >> "$APPLY_LOG"
import json, datetime
print(json.dumps({
    "ts": datetime.datetime.utcnow().isoformat() + "Z",
    "code": "$CODE",
    "target": "$TARGET_RAW",
    "date": "$NOW",
    "backup": "$BACKUP_DIR",
}, ensure_ascii=False))
PYEOF

echo ""
echo "✅ DNA Mutation 적용 완료."
echo "   백업: $BACKUP_DIR"
echo "   로그: $APPLY_LOG"
echo "   되돌리기: cp $BACKUP_DIR/$(basename "$TARGET_ABS") $TARGET_ABS"

exit 0
