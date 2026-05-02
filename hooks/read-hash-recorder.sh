#!/usr/bin/env bash
# read-hash-recorder.sh — PostToolUse(Read)
# Hash-Anchored Edit 교훈 흡수: Read 완료 시 파일 md5를 세션별 캐시에 저장
# edit-integrity-guard.sh가 이 캐시를 참조해 외부 변경 감지
# 원칙: 항상 exit 0 (블로킹 절대 금지)

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

# 필수 값 없음 → 조용히 종료
[ -z "$FILE" ] && exit 0
[ -z "$SESSION" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# 세션별 캐시 디렉토리 생성
CACHE_DIR="${TMPDIR:-${TEMP:-/tmp}}/ccd-edit-hash-$SESSION"
mkdir -p "$CACHE_DIR" 2>/dev/null || exit 0

SANITIZED=$(echo "$FILE" | sed 's|[/\\:* ]|_|g')
CACHED="$CACHE_DIR/$SANITIZED.md5"

# 파일 md5 저장
if command -v md5sum &>/dev/null; then
    md5sum "$FILE" 2>/dev/null | cut -d' ' -f1 > "$CACHED"
elif command -v certutil &>/dev/null; then
    certutil -hashfile "$FILE" MD5 2>/dev/null | sed -n '2p' | tr -d ' \r\n' > "$CACHED"
fi

# 항상 성공 (실패해도 블로킹 금지)
exit 0
