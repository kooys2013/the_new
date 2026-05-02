---
name: meta-eval
description: |
  (MASTER) 메타 평가 엔진 — 마스터 스킬 vs 플러그인 스킬 충돌 감지 + 벤치마크 + 하네스 재구성.
  
  동일 영역에서 마스터 스킬(7종)과 플러그인 스킬(gstack/bkit)이 겹칠 때,
  어떤 접근법이 우월한지 평가하고, 하네스 라우팅을 최적화한다.
  
  결과: (A) 플러그인이 우세 → 해당 영역 라우팅 변경
       (B) 마스터가 우세 → 플러그인에서 배울 점 흡수하여 마스터 업그레이드
       (C) 상호보완 → 파이프라인 순서 최적화
  
  트리거: "스킬 비교", "어떤 스킬이 나은지", "충돌", "겹치는 기능",
  "하네스 최적화", "스킬 벤치마크", "메타 평가", "meta-eval",
  "플러그인 vs 마스터", "기능 중복", "라우팅 최적화"
effort: high
user-invocable: true
model: claude-opus-4-7
---

# Meta-Eval: 스킬 충돌 평가 + 하네스 재구성 엔진

> 같은 일을 두 스킬이 한다면, 더 나은 쪽이 맡고 — 나머지는 배우거나 비킨다.

## Phase 0: 평가 범위 결정

사용자가 특정 영역을 지정하지 않으면, 전체 충돌 존을 스캔한다.

```
사용자: "스킬 벤치마크 해줘"
  → 전체 충돌 존 목록 제시 → 사용자가 선택 or "전부"

사용자: "problem-solver vs investigate 비교해줘"
  → 해당 존만 즉시 평가
```

### 충돌 존 맵 (알려진 고밀도 영역)

| Zone | 영역 | 마스터 | 플러그인 |
|------|------|--------|----------|
| Z1 | 기획·스펙 | planning-generator | plan-plus(bkit), office-hours, plan-*-review, autoplan |
| Z2 | 문제진단 | problem-solver | investigate(gstack) |
| Z3 | 검증·QA | verification-pipeline | qa, full-verify, review, health, code-review(bkit) |
| Z4 | 회고·학습 | retrospective-engine | retro(gstack), pdca analyze(bkit) |
| Z5 | 오케스트레이션 | meta-harness | pdca(bkit), autoplan(gstack), development-pipeline(bkit) |
| Z6 | 반복최적화 | ralph-strategy | pdca-iterator(bkit) |
| Z7 | 사고확장 | unbounded-engine | office-hours(gstack, 부분) |

**충돌 없는 영역** (플러그인 독점 — 평가 불필요):
- 디자인: design-*(gstack), ui-ux-pro-max
- 보안: cso, guard, careful
- 배포: ship, land-and-deploy, canary, setup-deploy
- 성능: benchmark, health
- 리서치: research-pipeline (마스터 독점)

## Phase 1: 시나리오 기반 채점

### 채점 기준 (5축 × 10점)

| 축 | 설명 | 측정 방법 |
|----|------|-----------|
| **Q (Quality)** | 출력 완성도·정확도 | 시나리오 실행 후 결과물 직접 비교 |
| **E (Efficiency)** | 컨텍스트 소비량·턴 수 | SKILL.md 길이 + preamble 오버헤드 + 평균 실행 턴 |
| **C (Composability)** | 다른 스킬과의 연결성 | 파이프라인 입출력 호환성 |
| **S (Specificity)** | 엣지케이스 처리력 | 예외 시나리오 대응 깊이 |
| **A (Autonomy)** | 사용자 개입 최소화 | 자동 판단 vs 질문 횟수 |

**총점 = Q×3 + E×2 + C×2 + S×1.5 + A×1.5** (가중합 100점 만점)

### 시나리오 설계 원칙

각 충돌 존에 대해 **3개 시나리오**를 생성한다:
1. **기본 시나리오**: 해당 영역의 가장 전형적인 작업
2. **복잡 시나리오**: 엣지케이스나 다른 영역과 연결되는 작업
3. **실패 시나리오**: 일부러 오류·모호함을 포함한 작업

```
예시 — Z2 (문제진단):
  기본: "API 응답이 500 에러를 반환한다. 원인 찾아줘"
  복잡: "간헐적 500 에러 + 특정 시간대에만 발생 + 로그 없음"
  실패: "에러 메시지가 'undefined' — 재현 불가, 로그 유실"
```

### 실행 방식

충돌 존 하나를 평가할 때:

```
1. 시나리오 3개 생성
2. 마스터 스킬 SKILL.md 정독 → 해당 스킬의 접근법으로 시뮬레이션
3. 플러그인 스킬 SKILL.md 정독 → 해당 스킬의 접근법으로 시뮬레이션
4. 5축 채점 (각 시나리오별)
5. 평균 산출 → 판정
```

**시뮬레이션 = 실제 실행이 아니라 "이 스킬이 이 시나리오를 받으면 어떤 단계를 밟을까"를 SKILL.md 기반으로 추론하는 것.**

실제 실행 벤치마크가 필요하면 사용자에게 제안:
```
"실제 실행 비교를 원하시면, 동일 시나리오로 두 스킬을 순차 실행합니다.
컨텍스트 소비가 크므로 1개 존씩 진행을 권장합니다."
```

## Phase 2: 판정 + 제안

채점 결과에 따라 3가지 판정:

### A. 플러그인 우세 (플러그인 총점 > 마스터 총점 × 1.2)

```
판정: 🔄 라우팅 변경
제안:
  - meta-harness 축약 경로에서 해당 영역 → 플러그인 스킬로 변경
  - 마스터 스킬은 해당 영역에서 비활성화 (삭제 아님)
  - rules/coding-tools.md 업데이트

예:
  Z2 판정 — investigate > problem-solver (코드 디버깅 한정)
  → meta-harness: "왜 안 되지?(코드)" → investigate 로 변경
  → problem-solver는 "비코드 문제진단" 전용으로 범위 축소
```

### B. 마스터 우세 (마스터 총점 > 플러그인 총점 × 1.2)

```
판정: 📈 마스터 업그레이드
제안:
  - 플러그인에서 배울 점 추출 (Q/E/C/S/A 중 플러그인이 높은 축)
  - 마스터 스킬 SKILL.md에 해당 기법 흡수
  - 라우팅은 유지

예:
  Z1 판정 — planning-generator > plan-plus (전체 기획)
  → plan-plus의 "YAGNI 리뷰" 기법을 planning-generator에 추가
  → office-hours의 "6개 강제 질문"을 planning-generator 초반에 삽입
```

### C. 상호보완 (격차 < 20%)

```
판정: 🔗 파이프라인 순서 최적화
제안:
  - 두 스킬이 서로 다른 강점을 가진 영역 식별
  - 순서 지정: "먼저 X → 그 다음 Y" 형태로 meta-harness 경로 수정
  - 또는 시나리오 유형별 분기

예:
  Z4 판정 — retrospective-engine ≈ retro(gstack) (상호보완)
  → "기술 회고" → retro (커밋 기반)
  → "프로세스/팀 회고" → retrospective-engine (KPT/AAR)
  → meta-harness에 분기 조건 추가
```

## Phase 3: 사용자 상담 (승인 필수)

**ALWAYS: 어떤 변경도 사용자 승인 없이 적용하지 않는다.**

AskUserQuestion으로 제안을 제시:

```
== Zone Z2: 문제진단 ==

[마스터] problem-solver: 72점
  Q:8 E:6 C:7 S:8 A:7 — 범용 진단, 비코드 문제에 강함

[플러그인] investigate (gstack): 81점
  Q:9 E:7 C:9 S:8 A:8 — 코드 디버깅 4단계, gstack 연동 우수

판정: 🔗 상호보완 (격차 12%)

제안:
  (A) 코드 버그는 investigate, 비코드 문제는 problem-solver로 분기
  (B) problem-solver에 investigate의 4단계 방법론 흡수
  (C) 현 상태 유지 (변경 없음)
  (D) 직접 수정안 제시
```

## Phase 4: 하네스 재구성 적용

승인받은 제안에 따라:

### 적용 대상 파일

| 변경 유형 | 파일 |
|-----------|------|
| 라우팅 변경 | `~/.claude/skills/meta-harness/SKILL.md` (축약 경로 테이블) |
| 마스터 업그레이드 | `~/.claude/skills/{skill}/SKILL.md` (해당 마스터 스킬) |
| 규칙 추가 | `~/.claude/rules/coding-tools.md` |
| 결과 기록 | `~/.claude/rules/meta-eval-log.md` (평가 이력) |

### 적용 절차

```
1. 변경 전 스냅샷 (git diff 용)
2. 파일 수정
3. 변경 내역을 meta-eval-log.md에 기록
4. 사용자에게 변경 완료 보고
```

### 평가 이력 기록 포맷 (meta-eval-log.md)

```markdown
## [날짜] Zone Z2: 문제진단

| | problem-solver | investigate |
|---|---|---|
| Q | 8 | 9 |
| E | 6 | 7 |
| C | 7 | 9 |
| S | 8 | 8 |
| A | 7 | 8 |
| **총점** | **72** | **81** |

**판정**: 상호보완
**적용**: 코드→investigate, 비코드→problem-solver 분기
**변경 파일**: meta-harness/SKILL.md (축약 경로 수정)
```

## 운영 규칙

- ALWAYS: 평가 시 양쪽 SKILL.md를 반드시 정독 (추측 금지)
- ALWAYS: 채점 근거를 시나리오별로 명시
- ALWAYS: 변경 전 사용자 승인 (Phase 3 필수)
- NEVER: "마스터가 당연히 낫다" 편향 금지 — 플러그인이 우세하면 인정
- NEVER: 삭제 제안 금지 — "비활성화" 또는 "범위 축소"까지만
- WHEN: 새 플러그인 설치 시 THEN: 충돌 존 재스캔 제안
- WHEN: 마스터 스킬 업데이트 시 THEN: 관련 존 재평가 제안
- WHEN: 3회 이상 같은 존에서 동일 판정 THEN: 영구 규칙으로 승격 (rules/)

## 빠른 실행 예시

```
사용자: "/meta-eval"
→ Phase 0: 전체 7개 충돌 존 목록 제시
→ 사용자: "Z2랑 Z4 해줘"
→ Phase 1: Z2 시나리오 3개 + Z4 시나리오 3개 생성 → 채점
→ Phase 2: Z2 판정 + Z4 판정
→ Phase 3: 사용자에게 제안 → 승인
→ Phase 4: meta-harness/rules 수정 → 완료 보고
```

```
사용자: "planning-generator vs plan-plus 비교"
→ 직접 Z1 진입 → Phase 1~4 순차 실행
```

## 주기적 재평가 제안

- WHEN: 스프린트 회고 시 (retro/retrospective-engine 실행 후)
- WHEN: 플러그인 업데이트 후 (harness-fit.sh 실행 후)
- WHEN: 새 마스터 스킬 생성 후
- 권장 주기: 월 1회 전체 존 재평가 or 분기 1회 전체 벤치마크
