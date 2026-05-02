#!/usr/bin/env bash
# vibe-sunsang-autostart — SessionStart 자동 변환 훅
# 역할: 세션 시작 시 최신 대화 로그를 백그라운드 변환 (incremental)
#       미온보딩 감지 시 additionalContext로 안내 주입
#
# 등록: settings.json SessionStart hooks (async: false for onboard check, then bg convert)
# 정책: 성공은 침묵 / 실패는 silent exit 0 (세션 블로킹 금지)

set +e

WORKSPACE=~/vibe-sunsang
CONFIG="$WORKSPACE/config/project_names.json"
PLUGIN_SCRIPT=~/.claude/plugins/cache/fivetaku/vibe-sunsang/2.0.1/scripts/convert_sessions.py
LAST_RUN_FILE=~/.claude/_cache/vibe-sunsang-last-run.txt

# --- Python3 가용 체크 ---
if ! command -v python3 >/dev/null 2>&1; then
  exit 0
fi

# --- 온보딩 미완료 감지 ---
if [ ! -f "$CONFIG" ]; then
  printf '{"additionalContext":"💡 바선생 첫 설정 필요: /vibe-sunsang 시작  (최초 1회 온보딩 — 프로젝트 이름 매핑 + 첫 변환 자동 실행)"}'
  exit 0
fi

# --- 오늘 이미 실행했으면 스킵 (중복 변환 방지) ---
TODAY=$(date +%Y-%m-%d)
LAST_RUN=$(cat "$LAST_RUN_FILE" 2>/dev/null | tr -d '[:space:]')
if [ "$LAST_RUN" = "$TODAY" ]; then
  exit 0
fi

# --- 플러그인 스크립트 존재 확인 ---
if [ ! -f "$PLUGIN_SCRIPT" ]; then
  exit 0
fi

# --- 백그라운드 증분 변환 실행 (세션 블로킹 없음) ---
(
  python3 "$PLUGIN_SCRIPT" 2>/dev/null
  echo "$TODAY" > "$LAST_RUN_FILE"
) &
disown

exit 0
