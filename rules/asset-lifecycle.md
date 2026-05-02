<!-- last-updated: 26/04/18 -->
---
description: 하네스 자산(skill/hook/rule/lesson) 라이프사이클 — active → dormant → candidate → archived, reinforced 역승격
paths:
  - "hooks/**"
  - "rules/**"
  - "skills/**"
  - ".claude/**"
---

# Asset Lifecycle (자산 라이프사이클)

> 하네스의 모든 자산(skills / hooks / rules / lessons)은 생성 → 활용 → 휴면 → 후보 → 졸업의 경로를 따른다.
> Daily Fit Loop가 매일 22:45 전이 판정 → **제안만**, 적용은 사용자 승인.

## 1. 상태 정의

| 상태 | 마커 | 기준 | 효과 |
|------|------|------|------|
| **active** | (기본) | 최근 60일 내 1회 이상 참조 | description 상시 로드 |
| **dormant** | `<!-- dormant:YYMMDD -->` | 60일 미참조 | 회색 표기, description은 유지 |
| **candidate-archive** | `<!-- candidate:YYMMDD -->` | 150일 미참조 (dormant +90d) | Layer 2가 P 코드로 제안 |
| **archived** | `archive/` 폴더 이동 | 사용자 `apply P` 승인 | description 언로드, 파일 보존 |
| **candidate-promote** | `<!-- candidate-promote:YYMMDD -->` | `[reinforced:YYMMDD,26/04/19]` 3회 60일 내 | rules/ 내에서 상위 티어(Core DNA) 제안 |

## 2. 전이 표

```
생성 → active (default)
            │
   60일 미참조
            ▼
         dormant
            │
   +90일 미참조 (총 150일)
            ▼
    candidate-archive ──┐
            │           │ 사용자 apply P
            ▼           │
    6개월 hook 발동 0회  │
            │           │
            ▼           ▼
         archived (archive/)
            │
   수동 apply A (resurrect)
            │
            ▼
         active 재진입
```

## 3. 역방향 (reinforced 승격)

```
active (rules/tactical tier)
  │ [reinforced:YYMMDD] 태그 3회 축적 (60일 내)
  ▼
candidate-promote
  │ 사용자 apply (수동, 룰 위치 이동)
  ▼
Core DNA tier (STRUCTURE.md §Core)
```

- `accumulated-lessons.md` 의 교훈이 `[reinforced:]` 3회면 `rules/` 승격 후보
- `rules/tactical/` 자산이 3회면 `rules/core/` (또는 STRUCTURE.md 상위) 승격 후보
- **WHEN** candidate-promote 발생 → **THEN** Layer 2 리포트 "DNA Mutation P" 후보에 포함

## 4. 측정 소스

| 자산 유형 | 참조 감지 경로 | 비고 |
|----------|---------------|------|
| skill | `_cache/harness/sessions.jsonl` `skills[]` 배열 | harness-session-collector.sh 누적 |
| hook | `_cache/obs/YYYY-WW.jsonl` `event` 필드 + 개별 훅 JSONL | obs.sh |
| rule | `lesson-reinforcer.sh` 적중 로그 + Edit/Write 발생 파일명 grep | PostToolUse 훅 |
| lesson | `accumulated-lessons.md` 내 `[reinforced:]` 태그 일자 | reinforcer가 갱신 |

## 5. ALWAYS / NEVER

- ALWAYS: dormant 전이는 **표기만** (파일 이동 금지)
- ALWAYS: candidate-archive 승인 전 `_cache/harness/mutation-YYMMDD.json`에 제안 기록
- ALWAYS: archived 자산도 `archive/` 보존 (삭제 금지) — resurrect 가능
- NEVER: Layer 2 analyzer가 파일을 자동 이동/삭제
- NEVER: `[reinforced:]` 태그를 수동 편집 (reinforcer만 갱신)
- NEVER: dormant 이내 자산을 candidate로 건너뛰기 (150일 경과 필수)

## 6. fit-escalation-ladder와의 관계

- `fit-escalation-ladder.md` 는 **규칙 강제화** 사다리 (warn → block → hook → archive)
- `asset-lifecycle.md` 는 **자산 사용 빈도** 사다리 (active → dormant → archived)
- **교집합**: 6개월 hook 발동 0회 → ladder "archive 졸업" == lifecycle "archived"
  - Layer 2가 양쪽 기준을 동시 만족 시 **P 코드 최우선순위**로 제안

## 7. 관련 파일

- `rules/daily-fit-contract.md` — 이 lifecycle을 구동하는 계약
- `rules/accumulated-lessons.md` — `[reinforced:]` 태그 실제 저장소
- `rules/fit-escalation-ladder.md` — hook 기반 강제화 사다리
- `skills/daily-fit-engine/SKILL.md` — Layer 2 analyzer가 참조
- `hooks/_setup/apply-daily-fit.sh` — 상태 전이 수동 실행기
