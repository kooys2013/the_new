---
paths:
  - "**/*"
---
# 도구 라우팅 규칙

## 사고↔코딩 분리 (절대)
- NEVER: 사고 스킬(L1) 실행 중 코드 작성
- NEVER: 코딩 도구(L3) 실행 중 방향 변경
- ALWAYS: 사고 결론을 코딩 도구의 입력으로 명시적 전달

## g-stack vs bkit
- NEVER: 같은 파일에 g-stack과 bkit 동시 사용

## 보안 검증 필수 경로
- WHEN: API 엔드포인트 추가/수정 THEN: /cso 실행
- WHEN: 인증/권한 로직 변경 THEN: /cso + /codex challenge
- WHEN: Supabase RLS 변경 THEN: /cso + staging 검증

## UX 검증 필수 경로
- WHEN: 신규 페이지/컴포넌트 완성 THEN: visual-proof
- WHEN: 반응형 작업 완료 THEN: visual-proof (desktop+mobile 최소 2디바이스)

## Context7 연동
- ALWAYS: 라이브러리 API 사용 시 Context7 MCP로 최신 문서 확인 후 코드 작성
- NEVER: Context7 없이 마이너 버전 이상 라이브러리 API를 기억에 의존

## 크로스 모델 검증
- WHEN: /codex와 Claude 상반된 의견 THEN: 양측 근거 제시 (User Sovereignty)

## 모델 에스컬레이션 (v2.5)
- WHEN: sonnet으로 2회 실패 THEN: opus로 승격 시도
- WHEN: opus로도 실패 THEN: /codex 교차검증
- WHEN: codex도 실패 THEN: unbounded-engine 재진입 (문제 재정의)
- ALWAYS: 에스컬레이션 결과를 CLAUDE.md WHEN...THEN에 모델 교훈으로 축적
- 상세 → rules/model-strategy.md 참조

## 병렬 개발
- ALWAYS: 워크트리 병렬 시 각 워크트리 CLAUDE.md에 파일 소유권 명시
- NEVER: 2개 이상 워크트리가 같은 파일 동시 수정

### 병렬 모드 범위 구분 (4분할)
| 모드 | 격리 수준 | 용도 | 대표 도구 |
|------|----------|------|----------|
| 세션 내 하위작업 조율 | 컨텍스트 공유 | 순차 의존 있는 작은 작업 묶음 | TodoWrite + 단일 에이전트 |
| 동시 에이전트 팬아웃 | 컨텍스트 격리 (세션 내) | 독립 작업 병렬 | Agent tool 다중 호출 |
| fresh subagent per task | 컨텍스트 완전 격리 + spec/quality 2단계 리뷰 | 작업 단위 구현 위임 | Agent tool (isolation 없음, fresh prompt) |
| 워크트리 물리 격리 | 파일시스템 격리 | 브랜치별 독립 커밋 | Agent tool `isolation:"worktree"` |

### 파일 소유권 매트릭스 (워크트리 병렬 시)
- ALWAYS: 병렬 시작 전 각 워크트리별 **파일 소유권** 테이블 명시 (A 담당 / B 담당 / 공유)
- ALWAYS: 공유 파일은 **읽기 전용**으로만 병렬 사용, 쓰기는 merge 단계에서 단일 워크트리에서
- NEVER: 공유 파일에서 동시 수정 발생 시 무시 — merge 전 conflict 수동 해결 필수

<!-- origin: obra/superpowers@using-git-worktrees+dispatching-parallel-agents | merged: 26/04/17 -->

### 보완 에이전트 아키타입 (누락분 매핑)
기존 Agent tool + bkit 플러그인 에이전트 외에 아래 2종은 개념 태그로 기록:
| 아키타입 | 역할 | 기존 매핑 |
|----------|------|----------|
| Critic | 주장·설계에 반증 시도 | harsh-critic 규칙 + `/codex:adversarial-review` |
| Tracer | 실행 경로/로그 추적으로 근본원인 추출 | gap-detector + problem-solver Phase 2-A |

<!-- origin: Yeachan-Heo/oh-my-claudecode@agent-archetypes | merged: 26/04/17 -->

## dory-knowledge 라우팅 (GO 프로젝트 전용)
- WHEN: 전략/원리/차트분석 판단 분기점 THEN: search_dory 또는 search_principle
- NEVER: 도리님 원문을 의역하여 인용 — 항상 원문 그대로
- NEVER: KORENO 업무·하네스 설정 등 무관 작업에서 호출
- ALWAYS: 검색 결과 0건이면 "KB에서 관련 내용 미발견" 명시
- ALWAYS: 도리님 원칙과 충돌 시 양쪽 근거 병렬 제시 + 사용자 판단
