#!/usr/bin/env bash
# stop-codex-bg.sh — Stop hook
# 세션 종료 시 코드 변경 감지 → Codex 리뷰 마커 생성
# (다음 SessionStart briefing에서 노출 → 자연스러운 /codex:review 유도)
# 원칙: 빠른 종료 필수 (Stop hook이 세션 종료를 지연시키면 안 됨)

# git 없으면 조용히 종료
command -v git &>/dev/null || exit 0

# 변경된 파일 목록 (staged + unstaged)
CHANGED=$(git diff --name-only HEAD 2>/dev/null)
[ -z "$CHANGED" ] && CHANGED=$(git status --porcelain 2>/dev/null | awk '{print $2}')
[ -z "$CHANGED" ] && exit 0

# 소스 코드 파일만 카운트 (wc -l — grep -c은 비매칭 시 exit 1)
CODE_CHANGED=$(echo "$CHANGED" | grep -E "\.(py|ts|tsx|js|jsx|go|rs|java|kt|swift|rb|php|cs|cpp|c)$" 2>/dev/null | wc -l | tr -d ' \r\n')
SQL_CHANGED=$(echo "$CHANGED" | grep -E "\.sql$" 2>/dev/null | wc -l | tr -d ' \r\n')
CODE_CHANGED=${CODE_CHANGED:-0}
SQL_CHANGED=${SQL_CHANGED:-0}
TOTAL_CODE=$((CODE_CHANGED + SQL_CHANGED))
[ "$TOTAL_CODE" -eq 0 ] && exit 0

# 민감 파일 감지
SENSITIVE_COUNT=$(echo "$CHANGED" | grep -iE "(auth|security|rls|schema|migration|\.sql|password|token|secret|credential|permission)" 2>/dev/null | wc -l | tr -d ' \r\n')
SENSITIVE_COUNT=${SENSITIVE_COUNT:-0}

# 추천 커맨드
if [ "$SENSITIVE_COUNT" -gt 0 ]; then
    RECOMMEND="adversarial"
    RECOMMEND_CMD="/codex:adversarial-review --scope working-tree"
    LABEL="민감 파일 포함"
else
    RECOMMEND="review"
    RECOMMEND_CMD="/codex:review --model spark --effort low"
    LABEL="일반 코드"
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')

# JSON 마커 저장 — Python이 경로를 직접 계산 (Git Bash POSIX 경로 → Windows 경로 변환 문제 우회)
python3 - <<PYEOF 2>/dev/null || true
import json, os, pathlib

cache_dir = pathlib.Path.home() / ".claude" / "_cache"
cache_dir.mkdir(parents=True, exist_ok=True)
pending = cache_dir / "codex-review-pending.json"

data = {
    "timestamp": "${TIMESTAMP}",
    "code_files": ${TOTAL_CODE},
    "sensitive_files": ${SENSITIVE_COUNT},
    "recommend": "${RECOMMEND}",
    "recommend_cmd": "${RECOMMEND_CMD}",
    "label": "${LABEL}",
}

with open(pending, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
PYEOF

# --- AUTO-EXEC (Codex 자동 리뷰 트리거 — v2.7) ---
# 리뷰 명령(review/adversarial-review)은 읽기 전용이므로 자동 실행 0 리스크
# 쓰기 명령(task --write/rescue)은 NEVER 자동
[ "${CODEX_AUTO_SKIP:-0}" = "1" ] && exit 0

CODEX_COMPANION="$HOME/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs"
[ -f "$CODEX_COMPANION" ] || exit 0
command -v node >/dev/null 2>&1 || exit 0
command -v codex >/dev/null 2>&1 || exit 0

# 일반 코드 → review / 민감 파일 → adversarial-review
if [ "$SENSITIVE_COUNT" -gt 0 ]; then
    AUTO_CMD="adversarial-review"
else
    AUTO_CMD="review"
fi

# 로그 경로 — Python으로 Windows 경로 안전 처리
AUTO_LOG=$(python3 - 2>/dev/null <<'PYEOF'
import pathlib, datetime
d = pathlib.Path.home() / ".claude" / "_cache" / "codex-auto-exec"
d.mkdir(parents=True, exist_ok=True)
print(d / f"{datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}.log")
PYEOF
)
[ -z "$AUTO_LOG" ] && exit 0

# Triple-detach: nohup + 백그라운드 & + disown + timeout 900s 하드 캡
# review는 companion 내부적으로 foreground — bash 레벨 detach 필수
# 모델: 기본(gpt-5.4) — ChatGPT 계정은 spark 미지원
# --scope working-tree로 쿼터 절약 (brach diff 아닌 working tree만)
(
    nohup timeout 900 node "$CODEX_COMPANION" "$AUTO_CMD" \
        --scope working-tree \
        >"$AUTO_LOG" 2>&1 </dev/null &
    disown
) >/dev/null 2>&1 &
disown

exit 0
