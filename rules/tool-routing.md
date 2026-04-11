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
