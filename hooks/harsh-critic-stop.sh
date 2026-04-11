#!/bin/bash
# Stop 이벤트 — harsh-critic EXTREME 체크
# 완료 선언 시 실제 검증 증거 확인

INPUT=$(cat)

echo "┌─── Harsh Critic Stop Check ───┐"
echo "│ SCP-1 조기종료: 요구사항 체크리스트 확인 필수"
echo "│ SCP-5 검증연극: 테스트 실행 tool call 증거 확인"
echo "│ E5 범위축소: 원본 요구 대비 누락 항목 점검"
echo "└────────────────────────────────┘"

# 현재는 경고만 출력 (blocking은 사용자가 settings.json에서 설정)
exit 0
