---
paths:
  - "**/*"
---
# 자동 트리거 규칙

## 기존 (유지)
- 테스트 3회 연속 실패 → retrospective-engine incident
- 스프린트 종료 → retrospective-engine + g-stack /retro
- 같은 에러 2회 반복 → unbounded-engine 재진입
- CLAUDE.md 50+ 항목 → retrospective-engine memory (정리)

## 추가 (v2.5)
- Supabase RLS 변경 → /cso 자동 제안
- 신규 npm 패키지 추가 → Context7 문서 확인 + /cso 공급체인
- .env 파일 변경 → security-scan.sh 즉시 실행
- 디자인 토큰/CSS 변수 변경 → /design-review 제안
- PR 생성 직전 → /review + /cso 필수 (skip 시 user-eye EXTREME)
- ralph-loop 5회+ 정체 → unbounded-engine + 사용자 알림
- visual-proof 점수 60 미만 → design-review 강제 진입

## 모델 에스컬레이션 트리거 (v2.5)
- sonnet 2회 연속 실패 (같은 작업) → opus 승격 제안
- ralph-loop 정체 2회 + 같은 에러 → model 승격 (haiku→sonnet→opus)
- usage-gate ORANGE(80%+) 진입 → opus 작업 보류 안내
- usage-gate RED(90%+) 진입 → haiku 전환 + 작업 보류 제안

## 교훈 승격 파이프라인 (v2.5)
- 같은 교훈 3회 축적 → rules/ 파일로 승격 제안
- rules/ 위반 반복 → hooks 강제화 제안
- 승격 후 CLAUDE.md에서 해당 항목 제거 (중복 방지)

## Self-Evolving System 트리거 (DNA 진화)

### 교훈 → 규칙 자동 승격 파이프라인
- WHEN: accumulated-lessons.md에 같은 ALWAYS/NEVER 3회+ 축적
  THEN: rules/ 승격 후보 제안 (retrospective-engine Phase 4.5 졸업 판정과 연동)
- WHEN: rules/ 규칙 위반 2회+ 반복
  THEN: hooks/ 강제화 후보 제안
- WHEN: hooks/ 훅이 6개월간 위반 0회
  THEN: 내면화 완료 → archive 제안

### DNA 진화 트리거 (세션 종료 시)
- WHEN: harsh-critic EXTREME 위반 발생한 세션
  THEN: retrospective-engine 필수 실행 + SCP 분류 + 규칙 mutation 제안
- WHEN: SCP-N 태그가 3세션 연속 동일 유형
  THEN: 해당 SCP 방어 로직 강화 제안 + unbounded-engine 재진입 검토
- WHEN: trend-harvester가 스택 변경 감지
  THEN: 영향받는 rules/ 파일 업데이트 제안

### 신뢰도 감쇠 (Confidence Decay)
- WHEN: accumulated-lessons.md 항목이 90일간 참조/강화 없음
  THEN: [STALE] 태그 부여 + 월간 정리 시 아카이브 후보
