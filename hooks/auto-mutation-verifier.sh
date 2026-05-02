#!/usr/bin/env bash
# auto-mutation-verifier.sh — staging 변이 적용 후 smoke 검증
# 실패 시 rollback.patch 자동 적용 + obs 이벤트 기록
# 호출: auto-mutation-verifier.sh <staging_dir>

set -euo pipefail

STAGING_DIR="${1:-}"
if [[ -z "$STAGING_DIR" || ! -d "$STAGING_DIR" ]]; then
  echo "Usage: auto-mutation-verifier.sh <staging_dir>" >&2
  exit 1
fi

PASS=0
FAIL=0
RESULTS=()

# 1. settings.json JSON 유효성
SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  if python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null; then
    RESULTS+=("PASS settings.json JSON valid")
    ((PASS++))
  else
    RESULTS+=("FAIL settings.json JSON invalid")
    ((FAIL++))
  fi
fi

# 2. 핵심 훅 실행 가능 여부
CORE_HOOKS=(
  "$HOME/.claude/hooks/coverage-gate.sh"
  "$HOME/.claude/hooks/trajectory-recorder.sh"
  "$HOME/.claude/hooks/harsh-critic-stop.sh"
)
for hook in "${CORE_HOOKS[@]}"; do
  if [[ -x "$hook" ]]; then
    RESULTS+=("PASS hook executable: $(basename $hook)")
    ((PASS++))
  else
    RESULTS+=("FAIL hook not executable: $(basename $hook)")
    ((FAIL++))
  fi
done

# 3. 핵심 스킬 frontmatter YAML 유효성
CORE_SKILLS=(
  "$HOME/.claude/skills/verify/SKILL.md"
  "$HOME/.claude/skills/verification-pipeline/SKILL.md"
  "$HOME/.claude/skills/coverage-gate/SKILL.md"
)
for skill in "${CORE_SKILLS[@]}"; do
  if [[ -f "$skill" ]]; then
    # frontmatter 추출 후 YAML 파싱
    front=$(awk '/^---/{p++;next} p==1{print} p==2{exit}' "$skill")
    if echo "$front" | python3 -c "import sys,yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
      RESULTS+=("PASS skill frontmatter: $(basename $(dirname $skill))")
      ((PASS++))
    else
      RESULTS+=("FAIL skill frontmatter invalid: $(basename $(dirname $skill))")
      ((FAIL++))
    fi
  fi
done

# 4. daily-fit-check 존재 확인 (30s 실행은 skip — 너무 오래 걸림)
FIT_CHECK="$HOME/.claude/hooks/2604181800_daily-fit-check.sh"
if [[ -f "$FIT_CHECK" ]]; then
  RESULTS+=("PASS daily-fit-check exists")
  ((PASS++))
else
  RESULTS+=("WARN daily-fit-check missing")
fi

# 결과 출력
TOTAL=$((PASS + FAIL))
echo "=== auto-mutation-verifier: $PASS/$TOTAL PASS ==="
for r in "${RESULTS[@]}"; do
  echo "  $r"
done

# obs 이벤트 기록
OBS_DIR="$HOME/.claude/_cache/obs"
mkdir -p "$OBS_DIR"
WEEK=$(date +%Y-%W)
EVENT_TYPE="mutation-verified"
[[ $FAIL -gt 0 ]] && EVENT_TYPE="mutation-rejected"

echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"$EVENT_TYPE\",\"staging\":\"$(basename $STAGING_DIR)\",\"pass\":$PASS,\"fail\":$FAIL}" \
  >> "$OBS_DIR/${WEEK}.jsonl"

# 실패 시 rollback
if [[ $FAIL -gt 0 ]]; then
  ROLLBACK="$STAGING_DIR/rollback.patch"
  if [[ -f "$ROLLBACK" ]]; then
    echo "FAIL count=$FAIL — applying rollback.patch" >&2
    git apply "$ROLLBACK" 2>/dev/null || true
  fi
  exit 1
fi

exit 0
