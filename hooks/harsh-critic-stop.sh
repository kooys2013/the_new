#!/bin/bash
# Stop 이벤트 — harsh-critic EXTREME 체크
# 완료 선언 시 실제 검증 증거 확인
# v4.1 (2605011600) — verify level grep 추가, dead code 정리

INPUT=$(cat)

# transcript_path 추출 (jq 없으면 node 사용)
TRANSCRIPT=$(echo "$INPUT" | node -e "let c=[];process.stdin.on('data',x=>c.push(x));process.stdin.on('end',()=>{try{console.log(JSON.parse(c.join('')).transcript_path||'')}catch(e){}})" 2>/dev/null)

# 최근 30줄에서 검증 흔적 탐색 (test/build/lint/npm/pytest/curl/playwright)
VERIFY_HIT=0
VERIFY_CLAIM_NO_LEVEL=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  TAIL_CONTENT=$(tail -c 50000 "$TRANSCRIPT" 2>/dev/null)

  # 실 검증 도구 흔적
  if echo "$TAIL_CONTENT" | grep -Eqi '"(test|build|lint|pytest|vitest|jest|playwright|curl -|npm run|pnpm |go test|cargo test)"|running tests|build succeeded'; then
    VERIFY_HIT=1
  fi

  # NEW (P0-2): verify 주장 + 레벨 누락 감지 (SCP-5 검증연극)
  # "검증 완료/통과/verified" 표현이 있는데 [L0~L5] 레벨 표기 없으면 위반
  if echo "$TAIL_CONTENT" | grep -Eqi '검증 (완료|통과|성공)|verified|verification (complete|passed)'; then
    if ! echo "$TAIL_CONTENT" | grep -qE '\[L[0-5][^0-9]'; then
      VERIFY_CLAIM_NO_LEVEL=1
    fi
  fi
fi

echo "┌─── Harsh Critic Stop Check ───┐"
echo "│ SCP-1 조기종료: 요구사항 체크리스트 확인 필수"
echo "│ SCP-5 검증연극: 테스트 실행 tool call 증거 확인"
echo "│ E5 범위축소: 원본 요구 대비 누락 항목 점검"
if [ "$VERIFY_HIT" -eq 0 ]; then
  echo "│ ⚠ 최근 tool call에 test/build/lint 흔적 없음 — 실검증 누락 의심"
  echo "│ → 다음 턴 시작 시 /verify 자가검증 자동 진입 권장 (L0~L4 자동 / L5 컨센트)"
fi

# NEW (P0-2): verify level 누락 알림
if [ "$VERIFY_CLAIM_NO_LEVEL" -eq 1 ]; then
  echo "│ 🚨 SCP-5 위험: '검증 완료' 주장에 [L0~L5] 레벨 표기 없음"
  echo "│   사용자 메모리 'feedback_always_show_verify_level' 위반"
  echo "│ → 다음 응답에서 검증 레벨 명시 필수 (예: '✅ 검증 통과 [L2 / Syntax+Regression]')"
fi

# v3 patch — coverage-gate 미달 + stop-verifier MISALIGNED 메시지
TRAJ_FILE="${HOME}/.claude/state/trajectory/$(basename $(pwd))/$(date +%Y-%m-%d).jsonl"
if [ -f "$TRAJ_FILE" ]; then
  COV_FAIL=$(tail -200 "$TRAJ_FILE" 2>/dev/null | grep -c "coverage-gate.*미달" || echo 0)
  if [ "$COV_FAIL" -gt 0 ]; then
    echo "│ ⚠ 분기 커버리지 미달 — 다음 턴 시작 시 coverage-gate 진입 권장"
  fi
fi

STOP_VER_LOG="${HOME}/.claude/state/trajectory/$(basename $(pwd))/stop-verifier.log"
if [ -f "$STOP_VER_LOG" ]; then
  MISALIGN=$(tail -50 "$STOP_VER_LOG" 2>/dev/null | grep -c "BLOCK\|MISALIGNED" || echo 0)
  if [ "$MISALIGN" -gt 0 ]; then
    echo "│ ⚠ Stop-verifier가 자금 직결 변경 BLOCK — vv-separator 진입 권장"
  fi
fi

# v4 patch — 자산 비대화 + Brier + 자동 적용률 알림
TOTAL_SKILLS=$(find ~/.claude/skills -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l)
if [ "$TOTAL_SKILLS" -ge 180 ]; then
  echo "│ ⚠ 자산 ${TOTAL_SKILLS}개 — 200개 임계 임박. asset-archiver 보고서 확인 권장."
fi

# Brier score 알림 (분기 누적이 0.3 초과 시)
BRIER_FILE="${HOME}/.claude/_state/brier-quarterly.jsonl"
if [ -f "$BRIER_FILE" ]; then
  LAST_BRIER=$(tail -1 "$BRIER_FILE" 2>/dev/null | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('score', 0.5))" 2>/dev/null || echo "0.5")
  if python3 -c "import sys; sys.exit(0 if float('$LAST_BRIER') > 0.3 else 1)" 2>/dev/null; then
    echo "│ ⚠ Brier ${LAST_BRIER} — calibration 저하. confidence 보정 필요."
  fi
fi

# 자동 적용률 알림 (10% 미만 시)
APPLY_FILE="${HOME}/.claude/_state/auto-apply-stats.jsonl"
if [ -f "$APPLY_FILE" ]; then
  RATE=$(tail -1 "$APPLY_FILE" 2>/dev/null | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('auto_apply_rate', 0))" 2>/dev/null || echo "0")
  if python3 -c "import sys; sys.exit(0 if float('$RATE') < 10 else 1)" 2>/dev/null; then
    echo "│ ⚠ 자동 적용률 ${RATE}% — Wave C(자가발전 폐루프) 미작동 또는 미적용."
  fi
fi

echo "└────────────────────────────────┘"

# 현재는 경고만 (blocking은 D+7 이후 block 승격 시 전환)
exit 0
