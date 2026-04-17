#!/bin/bash
# Stop 이벤트 — harsh-critic EXTREME 체크
# 완료 선언 시 실제 검증 증거 확인

INPUT=$(cat)

# transcript_path 추출 (jq 없으면 node 사용)
TRANSCRIPT=$(echo "$INPUT" | node -e "let c=[];process.stdin.on('data',x=>c.push(x));process.stdin.on('end',()=>{try{console.log(JSON.parse(c.join('')).transcript_path||'')}catch(e){}})" 2>/dev/null)

# 최근 30줄에서 검증 흔적 탐색 (test/build/lint/npm/pytest/curl/playwright)
VERIFY_HIT=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  if tail -c 50000 "$TRANSCRIPT" 2>/dev/null | grep -Eqi '"(test|build|lint|pytest|vitest|jest|playwright|curl -|npm run|pnpm |go test|cargo test)"|running tests|build succeeded'; then
    VERIFY_HIT=1
  fi
fi

echo "┌─── Harsh Critic Stop Check ───┐"
echo "│ SCP-1 조기종료: 요구사항 체크리스트 확인 필수"
echo "│ SCP-5 검증연극: 테스트 실행 tool call 증거 확인"
echo "│ E5 범위축소: 원본 요구 대비 누락 항목 점검"
if [ "$VERIFY_HIT" -eq 0 ]; then
  echo "│ ⚠ 최근 tool call에 test/build/lint 흔적 없음 — 실검증 누락 의심"
fi
echo "└────────────────────────────────┘"

# 현재는 경고만 (blocking은 D+7 이후 block 승격 시 전환)
exit 0
