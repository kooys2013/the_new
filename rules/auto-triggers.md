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

## 플랜 모드 × planning-generator 연결 (v2.6)
- WHEN: ExitPlanMode 호출 직후 THEN: 메인 스레드가 plan 파일 구조 점검 → PRD/FS/IA/UF 4섹션 없으면 planning-generator 프레임으로 재구조화 제안 (Phase 1-D 마이크로태스크 포함)

## 병목 감지 + 즉시 대응 트리거 (v2.6)

> "속도가 안 나올 때" → 수정 전 반드시 병목 유형 진단 먼저

| 감지 신호 | 강제 대응 | 근거 |
|----------|----------|------|
| 같은 파일/함수에서 2회 연속 수정 실패 | **problem-solver Phase 2-A 강제 진입** (근본원인 미확인 시 수정 금지) | SCP-5 + [SCP-3] |
| 동일 에러 메시지 2회 이상 등장 | 수정 금지 → 4단계 진단 (조사→패턴→가설검증→구현) 먼저 | Phase 2-A 철칙 |
| 작업 소요 시간이 예상의 3배 초과 | **unbounded-engine 재진입** — 문제 재정의 (방향 자체 점검) | SCP-3 복잡도회피 |
| 컨텍스트 60% 초과 + 작업 진행 중 | **/compact 즉시** + 핵심 제약 3줄 재주입 후 재개 | SCP-2 컨텍스트열화 |
| 3회 이상 실패 후 "일단 해보자" 충동 | **중단** → problem-solver Phase 2-A 3회실패 에스컬레이션 경로 | Phase 2-A 3회규칙 |

### 병목 진단 5초 루틴

```
"지금 왜 느린가?" 자문:
1. 에러 메시지가 같은가? → Phase 2-A (근본원인)
2. 파일 구조가 머릿속에 없는가? → /compact + Explore agent
3. 방향 자체가 맞는지 모르겠는가? → unbounded-engine
4. 도구를 잘못 쓰고 있는가? → tool-routing.md 참조
5. 모델 한계인가? → model-strategy 에스컬레이션
```

<!-- origin: bottleneck-response-system | merged: 26/04/17 -->

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

## dory-knowledge 자동 트리거 (v1.0)
- WHEN: 전략 카드(P/S/MP/MS/DK) 작업 시작
  THEN: search_principle("{카드 원천 원리}") 1회 호출
- WHEN: SL/TP/진입조건 파라미터 변경
  THEN: search_dory("{파라미터} 기준") 호출 + 도리님 렌즈 판정
- WHEN: 백테스트 결과 분석 단계
  THEN: search_dory("백테스트") + search_principle("등배원리") 호출
- WHEN: Phase A/B 보고서 작성
  THEN: search_dory("Phase A 검증") 호출

## Codex 자동 트리거 (공식 플러그인 v1.0)
- WHEN: PR 생성 직전 THEN: `/codex:review` 실행 (g-stack /review + 교차검증)
- WHEN: problem-solver 2회 실패 THEN: `/codex:rescue` 위임 제안
- WHEN: 아키텍처·전략 결정 THEN: `/codex:adversarial-review` 제안
- WHEN: 인증/보안 코드 변경 THEN: `/cso` + `/codex:adversarial-review 인증·데이터 취약점' 병행

## 리뷰 게이트 규칙 (--enable-review-gate)
- NEVER: 무인 세션에서 리뷰 게이트 활성화 (Claude↔Codex 루프 → 사용량 급소모)
- WHEN: 리뷰 게이트 활성화 THEN: 30분 제한 + 유인 감시 필수
- WHEN: 리뷰 게이트 3회+ 반복 차단 THEN: 즉시 비활성화 (`/codex:setup --disable-review-gate`)

## dory-knowledge 호출 금지 상황
- 단순 코드 구현 (UI, API, DB 스키마 — 원리와 무관)
- KORENO 업무 / 하네스 설정 / 일반 기술 리서치
- 같은 세션에서 같은 쿼리로 이미 검색한 경우
