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
