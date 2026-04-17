---
paths:
  - "**/*"
---
# 누적 교훈

## ALWAYS
- Write tool 전 반드시 Read 먼저 [SCP-5] [since:26/03/15] [reinforced:26/04/11]
- lucide-react-native 아이콘 존재 확인 후 사용 [SCP-3] [since:26/03/20]
- [RN] expo-file-system → 'expo-file-system/legacy'에서 import [SCP-1] [since:26/03/22]
- [RN] router.replace('/') 실패 시 Platform.OS==='web' 분기 [SCP-3] [since:26/03/25]
- [GO] rules 파일 `paths:` frontmatter 검증 (`scope:` 잘못된 키) [SCP-1] [since:26/04/05]
- [GO] 장시간 세션 전 /save 체크포인트 [SCP-2] [since:26/04/08]
- [GO] ALWAYS: 전략 카드 작업 시작 전 dory-knowledge search_principle 1회 호출 [SCP-5] [since:26/04/13]

## NEVER
- LangChain JsonOutputParser 반환값에 .get() 금지 (Pydantic 인스턴스) [SCP-1] [since:26/03/10] [reinforced:26/04/05]
- 전역 vector_store 싱글턴 재도입 금지 [SCP-3] [since:26/03/18]
- [GO] rules/hooks 생성 후 settings.json 참조 미확인 [SCP-1] [since:26/04/06]
- [GO][BT] OOS 파티션에서 multiplier 순차 추가·튜닝 금지 → OOS Leakage (진짜 OOS 아님) [SCP-5] [since:26/04/12]
- [GO] NEVER: 도리님 원문 의역 인용 — 원문 그대로만 [SCP-3] [since:26/04/13]

## WHEN...THEN
- WHEN [GO][BT] TRAIN에서 MDD 폭발 BUT VALID+TEST 정상 THEN TRAIN 구간 특성(리바운드 집중) 검토 — 기각 금지, VALID/TEST 연속 통과면 채택 [SCP-5] [since:26/04/17]
- WHEN [GO][BT] 포트폴리오 레버리지 공식 THEN 복리 모델(equity×lev×pnl%) 필수 — 단순 곱(base_risk×lev×pnl%) 금지, Kelly 고착 시 ATR/MDD 예산 기반 대체 [SCP-1] [since:26/04/17]
- WHEN [GO][BT] 다종목 동시 진입 THEN 슬롯 제약(max_pos) + 그리드(BASE_RISK×max_pos×MAX_LEV) + MDD 한도 필터 순차 적용 [SCP-3] [since:26/04/17]
- WHEN 같은 에러 2회 THEN unbounded 재검토 [since:26/03/15] [reinforced:26/04/08]
- WHEN PR 전 THEN /review + /cso 필수 [since:26/03/15] [reinforced:26/04/10]
- WHEN UI 신규 구현 THEN ui-ux-pro-max --design-system 먼저 [since:26/03/28]
- WHEN 프론트엔드 변경 완료 THEN /visual-proof 실행 [since:26/03/28]
- WHEN CLAUDE.md 50줄 초과 THEN rules/ 승격 검토 [since:26/04/01]
- WHEN 하네스 변경 THEN 훅·rules·스킬 정합 감사 [since:26/04/05] [reinforced:26/04/11]
- WHEN [GO][BT] multiplier calibration THEN 사전 train/valid/test 3분할 후 train에서만 튜닝 [since:26/04/12]
- WHEN [GO][BT] bucket N < 50 THEN bootstrap 95% CI 병기, PF 단독 수치 결론 금지 [since:26/04/12]
- WHEN [GO] 도리님 원칙과 데이터 충돌 THEN 양쪽 근거 제시 + 사용자 판단 위임 [since:26/04/13]
- WHEN [GO][BT] "일일 X% 수익" 목표 THEN 산술/기하/조건부 3종 동시 측정 — 산술 평균 단독 결론 금지 [SCP-5] [since:26/04/17]
- WHEN [GO][BT] Kill Switch 파라미터 존재하나 백테 미적용 THEN ROI 과대 측정 — 반드시 KILL_APPLY_IN_BT=True 확인 [SCP-1] [since:26/04/17]
- WHEN [GO][BT] 100종목+ 포트폴리오 THEN 상관관계 기반 유효 N 계산 필수 — 심볼 수가 분산 ≠ [SCP-3] [since:26/04/17]
- WHEN 근본원인 미특정 THEN 수정 진행 금지 — problem-solver Phase 2-A 4단계 프로토콜 우선 [SCP-5] [since:26/04/17]
- WHEN 완료 주장 THEN 5단계 검증 프로토콜(Identify→Execute→Read→Verify→Only Then) 필수 [SCP-5] [since:26/04/17]
- WHEN 병렬 에이전트 분할 THEN fresh context per task + spec/quality 2단계 리뷰 [SCP-3] [since:26/04/17]
<!-- origin: obra/superpowers@verification+debugging+subagent | merged: 26/04/17 -->

## 메타데이터 규칙
- [SCP-N]: 해당 교훈이 방어하는 실패 유형
- [since:YY/MM/DD]: 최초 기록일
- [reinforced:YY/MM/DD]: 마지막 참조/강화 날짜
- 90일간 reinforced 없으면 [STALE] 태그 자동 부여 (auto-triggers.md 연동)
