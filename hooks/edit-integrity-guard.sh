#!/usr/bin/env bash
# edit-integrity-guard.sh — PreToolUse(Edit|Write)
# Hash-Anchored Edit 교훈 흡수: Read 이후 파일 외부 변경 감지
# exit 0 = 통과, exit 2 = 외부 변경 감지 (재Read 권고)
# 원칙: 실패해도 exit 0 폴백 (블로킹 금지)

INPUT=$(cat)

# Python으로 JSON 파싱 (jq 의존성 제거)
parse_json() {
    python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    key = '$1'
    parts = key.split('.')
    v = d
    for p in parts:
        v = v.get(p, '')
    print(v or '')
except:
    print('')
" <<< "$INPUT" 2>/dev/null
}

FILE=$(parse_json "tool_input.file_path")
SESSION=$(parse_json "session_id")

# 필수 값 없음 → 통과
[ -z "$FILE" ] && exit 0
[ -z "$SESSION" ] && exit 0

# 신규 파일 Write → 통과 (해시 비교 대상 없음)
[ ! -f "$FILE" ] && exit 0

# 세션 캐시 경로
CACHE_DIR="${TMPDIR:-${TEMP:-/tmp}}/ccd-edit-hash-$SESSION"
SANITIZED=$(echo "$FILE" | sed 's|[/\\:* ]|_|g')
CACHED="$CACHE_DIR/$SANITIZED.md5"

# Read 기록 없음 → 통과 (첫 Edit이거나 Read 없이 진행하는 경우 허용)
[ ! -f "$CACHED" ] && exit 0

# 현재 파일 해시 계산
CURRENT=""
if command -v md5sum &>/dev/null; then
    CURRENT=$(md5sum "$FILE" 2>/dev/null | cut -d' ' -f1)
elif command -v certutil &>/dev/null; then
    CURRENT=$(certutil -hashfile "$FILE" MD5 2>/dev/null | sed -n '2p' | tr -d ' \r\n')
fi

# 해시 계산 실패 → 통과 (블로킹 금지)
[ -z "$CURRENT" ] && exit 0

CACHED_HASH=$(cat "$CACHED" 2>/dev/null)

# 해시 불일치 → 경고 + exit 2
if [ "$CURRENT" != "$CACHED_HASH" ]; then
    echo "⚠ [edit-integrity-guard] 파일이 Read 이후 외부에서 변경됨" >&2
    echo "  파일: $FILE" >&2
    echo "  저장된 해시: $CACHED_HASH" >&2
    echo "  현재 해시:   $CURRENT" >&2
    echo "→ 권장 다음 단계: Read 재실행 후 Edit 재시도 (병렬 워크트리 race 가능)" >&2
    exit 2
fi

exit 0
