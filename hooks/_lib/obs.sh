#!/usr/bin/env bash
# obs.sh — 3축 관찰 공통 라이브러리
# E2E·UX·Drift 훅이 source 하는 boilerplate + 리소스 가드 + JSONL append
#
# Usage (훅 상단):
#   source "$(dirname "$0")/_lib/obs.sh"
#   obs_init   # set -euo pipefail + trap exit 0
#   obs_resource_check || exit 0
#   obs_append session-start info '{"source":"trace-context-boot"}'
#
# 원칙: 실패 silent exit 0 (세션 영향 금지)

# --- 초기화 + 안전망 ---------------------------------------------------------
obs_init() {
  # 각 훅에서 호출 — 실패 시 세션 영향 금지
  set -euo pipefail 2>/dev/null || true
  # ERR/EXIT 발생해도 조용히 종료 (Stop/PostToolUse 체인 보호)
  trap 'exit 0' ERR
}

# --- 디렉토리 경로 -----------------------------------------------------------
OBS_DIR="${CLAUDE_OBS_DIR:-$HOME/.claude/_cache/obs}"
DRIFT_DIR="${CLAUDE_DRIFT_DIR:-$HOME/.claude/_cache/drift}"

obs_ensure_dirs() {
  mkdir -p "$OBS_DIR" "$DRIFT_DIR" 2>/dev/null || return 0
}

# --- 주간 rotate: YYYY-WW.jsonl ---------------------------------------------
obs_current_file() {
  # Git Bash on Windows: date +%G-%V (ISO week)
  local week
  week=$(date -u +%G-%V 2>/dev/null || echo "unknown")
  echo "$OBS_DIR/${week}.jsonl"
}

# --- JSONL append (Python으로 안전 escape) -----------------------------------
# Usage: obs_append <event> <severity> <payload_json_or_empty>
#   event:    session-start / trace-tag / drift-detect / ux-suggest / ...
#   severity: info / warn / critical
#   payload:  '{"k":"v",...}' 또는 빈 문자열
obs_append() {
  local event="${1:-unknown}"
  local severity="${2:-info}"
  local payload="${3:-}"

  obs_ensure_dirs
  local target
  target=$(obs_current_file)

  # Python으로 JSON 생성 (Windows Git Bash 호환, jq 없음)
  python3 - "$target" "$event" "$severity" "$payload" <<'PYEOF' 2>/dev/null || return 0
import json, sys, datetime, os
target, event, severity, payload_raw = sys.argv[1:5]
try:
    payload = json.loads(payload_raw) if payload_raw.strip() else {}
except Exception:
    payload = {"raw": payload_raw[:200]}
record = {
    "ts": datetime.datetime.utcnow().isoformat() + "Z",
    "event": event,
    "severity": severity,
    "pid": os.getpid(),
    "payload": payload,
}
try:
    with open(target, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
except Exception:
    pass
PYEOF
  return 0
}

# --- 리소스 가드 -------------------------------------------------------------
# 목표: CPU 200% / RAM 4GB / Docker 활성 시 훅이 무거운 작업 skip
# 반환: 0 = 계속, 1 = skip (훅이 exit 0 하도록 유도)
obs_resource_check() {
  local ram_limit_gb="${CLAUDE_HOOK_RAM_LIMIT_GB:-4}"

  # Git Bash / Windows 환경: /proc/meminfo 존재 여부로 분기
  if [ -r /proc/meminfo ]; then
    local avail_kb
    avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    local avail_gb=$((avail_kb / 1024 / 1024))
    if [ "$avail_gb" -gt 0 ] && [ "$avail_gb" -lt "$ram_limit_gb" ]; then
      return 1
    fi
  fi

  # Docker 데몬이 돌고 있으면 무거운 작업 skip (외부 프로세스 정책)
  if [ "${CLAUDE_OBS_SKIP_ON_DOCKER:-0}" = "1" ]; then
    if command -v docker >/dev/null 2>&1; then
      if docker info >/dev/null 2>&1; then
        return 1
      fi
    fi
  fi

  return 0
}

# --- session correlation id (best-effort) ------------------------------------
obs_session_id() {
  # CLAUDE_SESSION_ID 같은 env 가 있으면 사용, 없으면 PID로 대체
  echo "${CLAUDE_SESSION_ID:-pid-$$}"
}
