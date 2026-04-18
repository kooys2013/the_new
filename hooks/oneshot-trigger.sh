#!/usr/bin/env bash
# oneshot-trigger.sh — UserPromptSubmit
# 사용자 프롬프트에서 한방 모드 키워드 감지 → /oneshot 자동 라우팅 힌트 출력
# 사용자 선호: 수동 슬래시 입력 회피, hooks 자동 발동 우선 (feedback_hook_automation.md)
# exit 0 = 통과, additionalContext만 추가 (블로킹 금지)

INPUT=$(cat)

parse_json() {
    python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('$1', '') or '')
except:
    print('')
" <<< "$INPUT" 2>/dev/null
}

PROMPT=$(parse_json "prompt")
[ -z "$PROMPT" ] && exit 0

# 이미 /oneshot 명시 → 중복 알림 회피
echo "$PROMPT" | grep -qE '^/oneshot' && exit 0

# 키워드 매트릭스 (대소문자 무관)
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

SUGGEST=""

# advise (비실행, 가장 가벼움 → 우선 매칭)
if echo "$PROMPT" | grep -qE '무한조언|어드바이스|조언해줘|어떻게 생각|의견 좀|갈림길|판단이 안|뭘 놓치|사각지대'; then
    SUGGEST="advise"
fi

# verify
if echo "$PROMPT" | grep -qE '한방에 검증|풀 검증|배포 전 완전 검증|6레이어 검증|다층 검증|출시 전 검증'; then
    SUGGEST="verify"
fi

# dev (가장 무거움 → 마지막에 매칭하여 verify/advise 우선권 유지)
if echo "$PROMPT" | grep -qE '한방에 개발|풀 파이프라인 개발|처음부터 끝까지 만들|전부 알아서 해|ㄱㄱ 개발|6레이어 개발|자율 개발 파이프라인'; then
    [ -z "$SUGGEST" ] && SUGGEST="dev"
fi

# setup
if echo "$PROMPT" | grep -qE '하네스 설정|프로젝트 셋업|harness fit|하네스 핏|claude\.md 생성|하네스 최적화|하네스 점검'; then
    [ -z "$SUGGEST" ] && SUGGEST="setup"
fi

[ -z "$SUGGEST" ] && exit 0

# additionalContext 출력 (Claude 프롬프트에 추가됨)
cat <<EOF
[oneshot-trigger] 한방 모드 키워드 감지 → 자동 라우팅 권고: \`/oneshot $SUGGEST "<원래 요청>"\`
- 사용자는 hooks 기반 자동 발동을 선호함 (수동 슬래시 입력 회피)
- 현재 요청을 unbounded-engine "$SUGGEST 모드"로 즉시 진입 처리
- 진입 메시지: "한방 모드 진입 — Phase A부터 시작합니다 (사고→구현→검증→회고). 중단하려면 Esc."
EOF

exit 0
