#!/usr/bin/env bash
# Z-1 7일 의례 — 일일 use-counter 스냅샷
# 이벤트: cron 매일 23:00 / SLA: ≤2s / 출력: _state/usage-day-YYMMDD.json
# silent exit 0 — Layer 3 reinforcer 정책 준수

set -u
exec 2>/dev/null

CLAUDE_DIR="${HOME}/.claude"
STATE_DIR="${CLAUDE_DIR}/_state"
CACHE_DIR="${CLAUDE_DIR}/_cache"
BASELINE="${STATE_DIR}/baseline-2605011250.json"
TS=$(date '+%Y-%m-%dT%H:%M%z' 2>/dev/null || echo "unknown")
DAY=$(date '+%y%m%d' 2>/dev/null || echo "000000")
OUT="${STATE_DIR}/usage-day-${DAY}.json"

# baseline 미존재 시 의례 비활성 → silent skip
[ -f "${BASELINE}" ] || exit 0
mkdir -p "${STATE_DIR}" 2>/dev/null

# === 자산 호출 카운트 집계 (best-effort, 실패해도 silent) ===
SESSIONS_LOG="${CACHE_DIR}/harness/sessions.jsonl"
OBS_DIR="${CACHE_DIR}/obs"

_to_int() {
  local v="${1:-0}"
  v="${v//[^0-9]/}"
  echo "${v:-0}"
}

count_skill_refs() {
  local name="$1"
  local a=0 b=0
  if [ -f "${SESSIONS_LOG}" ]; then
    a=$(grep -c "\"${name}\"" "${SESSIONS_LOG}" 2>/dev/null)
    a=$(_to_int "$a")
  fi
  if [ -d "${OBS_DIR}" ] && ls "${OBS_DIR}"/*.jsonl >/dev/null 2>&1; then
    b=$(grep -h "\"skill\":\"${name}\"" "${OBS_DIR}"/*.jsonl 2>/dev/null | wc -l)
    b=$(_to_int "$b")
  fi
  echo $((a + b))
}

count_hook_fires() {
  local name="$1"
  local n=0
  if [ -d "${OBS_DIR}" ] && ls "${OBS_DIR}"/*.jsonl >/dev/null 2>&1; then
    n=$(grep -h "\"hook\":\"${name}\"" "${OBS_DIR}"/*.jsonl 2>/dev/null | wc -l)
    n=$(_to_int "$n")
  fi
  echo "$n"
}

# baseline 자산 목록 추출 (jq 없이도 동작 / Windows python 호환 path)
BASELINE_WIN=$(cygpath -w "${BASELINE}" 2>/dev/null || echo "${BASELINE}")
get_array() {
  local key="$1"
  python3 -c "
import json,sys
try:
  d=json.load(open(r'${BASELINE_WIN}'))
  for x in d.get('${key}',[]): print(x)
except: pass
" 2>/dev/null | tr -d '\r'
}

# JSON 출력 빌드
{
  echo "{"
  echo "  \"day\": \"${DAY}\","
  echo "  \"ts\": \"${TS}\","
  echo "  \"baseline\": \"baseline-2605011250\","
  echo "  \"skills\": {"
  first=1
  for key in wave_d_skills wave_e_skills; do
    while IFS= read -r s; do
      [ -z "$s" ] && continue
      [ $first -eq 0 ] && echo ","
      printf "    \"%s\": %s" "$s" "$(count_skill_refs "$s")"
      first=0
    done < <(get_array "$key")
  done
  echo ""
  echo "  },"
  echo "  \"hooks\": {"
  first=1
  for key in wave_d_hooks wave_e_hooks wave_c_hooks; do
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      [ $first -eq 0 ] && echo ","
      printf "    \"%s\": %s" "$h" "$(count_hook_fires "$h")"
      first=0
    done < <(get_array "$key")
  done
  echo ""
  echo "  }"
  echo "}"
} > "${OUT}" 2>/dev/null

exit 0
