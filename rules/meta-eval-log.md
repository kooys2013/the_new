---
description: meta-eval 평가 이력 — 마스터 vs 플러그인 스킬 벤치마크 결과 및 적용 기록
paths:
  - "__on_demand_only__"
---

# Meta-Eval 평가 이력

## [2026-04-11] 전체 7개 존 초회 평가

### 요약

| Zone | 마스터 | 점수 | 플러그인 | 점수 | 판정 | 적용 |
|------|--------|------|----------|------|------|------|
| Z1 기획 | planning-generator | 80.5 | office-hours+autoplan | 77 | 상호보완 | 순차 파이프라인 |
| Z2 문제진단 | problem-solver | 79.5 | investigate | 73.5 | 마스터 우세 | investigate의 cross-project learnings 흡수 |
| Z3 검증 | verification-pipeline | 84 | qa+full-verify+review | 81.5 | 상호보완 | 마스터=프레임워크, 플러그인=실행 |
| Z4 회고 | retrospective-engine | 81 | retro | 77.5 | 상호보완 | retro(데이터) → retrospective-engine(분석) |
| Z5 오케스트레이션 | meta-harness | 80.5 | pdca | 82 | 상호보완 | 마스터=라우터, bkit=실행엔진 |
| Z6 반복최적화 | ralph-strategy | 76.5 | pdca-iterator | 77.5 | 상호보완 | 마스터=전략, 플러그인=루프 |
| Z7 사고확장 | unbounded-engine | 80 | office-hours | 66 | 마스터 우세 | 마스터 독점 |

### 핵심 원칙 도출

```
마스터 = 사고 프레임워크 (WHAT을 결정)
플러그인 = 실행 자동화 (HOW를 수행)
같은 단계에서 병렬 실행 = 토큰 낭비
순차 연결 (사고→실행) = 시너지
교차검증 필요 시 = /codex (다른 모델)
```

### 적용된 변경

1. **meta-harness 축약 경로 전면 재구성** — 역할 분담 칼럼 추가, 병렬 중복 제거
2. **Z2 해소** — problem-solver에 investigate의 cross-project learnings 흡수
3. **Z2 라우팅** — "코드 버그 → problem-solver → 수정 → qa" (investigate 제거)
4. **Z4 라우팅** — "스프린트 종료 → retro(데이터) → retrospective-engine(분석)"
5. **Z3 라우팅** — "QA/검증 → verification(게이트) → qa+full-verify(실행)"
