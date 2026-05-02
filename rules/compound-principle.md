<!-- origin: EveryInc/compound-engineering-plugin philosophy only | adapted: 26/04/19 -->
---
description: Compound Engineering 원칙 — 각 엔지니어링 작업이 다음 작업을 쉽게 만들도록 설계
paths:
  - "__on_demand_only__"
---

# Compound Principle (복리 엔지니어링 원칙)

> "각 단위 엔지니어링 작업은 그 다음 작업을 더 쉽게 만들어야 한다." — EveryInc

커맨드(`/ce-*` 7종)는 **도입하지 않는다**. 기존 하네스가 이미 해당 역할을 커버하기 때문. 이 파일은 **원칙만** 추출해 전역 규칙으로 내재화한다.

---

## §1. 원칙 (3줄)

- **정의**: 지금 하는 작업의 산출물(코드·테스트·문서·회고)이 *다음 유사 작업의 비용을 감소*시키면 compound다.
- **예시**: 실패 시나리오를 테스트로 고정 → 동일 실패 자동 방지. 회고를 `accumulated-lessons.md`에 승격 → 다음 결정 시 grep 1회로 회피.
- **안티패턴**: 한 번 쓰고 버리는 프롬프트, 주석 없는 패치, 재현 불가능한 fix, "나중에 정리"라고 미룬 교훈.

---

## §2. 기존 스킬 연결 맵 (중복 선언이 아닌 통합)

| 기존 자산 | compound 기여 |
|----------|--------------|
| `skills/retrospective-engine` | 회고 → ALWAYS/NEVER 추출 → 다음 세션 비용 ↓ |
| `skills/problem-solver` Phase 2-A | 3회 실패 시 unbounded 역류 → 같은 실패 영구 방지 |
| `rules/accumulated-lessons.md` | 3회 반복 → rules/ 승격 → 하네스 DNA 진화 |
| `rules/asset-lifecycle.md` | `[reinforced:]` 태그 → 자산이 사용될수록 강화 |
| `skills/daily-fit-engine` Layer 3 | PostToolUse 훅이 자동 reinforce → compound loop 자동화 |
| `hooks/2604181802_lesson-reinforcer.sh` | Edit/Write 시 교훈 참조 자동 감지 |
| `/codex:review` + `harsh-critic` | 독립 시각 주입 → 다음 유사 판단에서 편향 감소 |

**핵심**: compound-engineering 플러그인의 7 커맨드 (`/ce-setup` `/ce-ideate` `/ce-brainstorm` `/ce-plan` `/ce-work` `/ce-code-review` `/ce-compound`)는 위 맵에서 **이미 커버됨**. 커맨드 추가는 역행이므로 금지.

---

## §3. 실행 프로토콜 (작업 완료 시 1 자문)

작업을 "완료"로 선언하기 직전, **한 줄만** 자문하라:

> **"이 작업이 다음 유사 작업의 비용을 낮췄는가?"**

답이 "아니오" 또는 "모르겠다"면 다음 중 하나를 수행 후 완료 선언:

1. **테스트 추가**: 방금 고친 버그를 재현하는 테스트 작성 (compound: 회귀 방지)
2. **교훈 기록**: `accumulated-lessons.md` 에 ALWAYS/NEVER 1줄 추가 (compound: 유형 인식)
3. **주석 삽입**: "왜 이렇게 했는지" 의 근거 주석 (compound: 미래 자신의 맥락 복원 비용 ↓)
4. **훅·스킬 제안**: 같은 실수를 자동 감지할 메커니즘 설계 (compound: 자동화)

---

## §4. 승격 기준 (rules/ 내부 이동)

이 파일이 다음 조건을 **모두** 만족하면 `rules/accumulated-lessons.md` 본문으로 통합 검토:

- 참조 3회 (daily-fit-engine Layer 3가 `[reinforced:]` 태그 갱신)
- §3 실행 프로토콜의 결과가 실제 자산 생성으로 이어진 기록 3건 이상
- T+90일 이내

**승격 후 처리**: 이 파일은 archive 이동 → 원칙은 Core DNA 티어(STRUCTURE.md §Core)로 진입.

---

## §5. 명시적 제외 (안티패턴 목록)

다음은 **도입 금지** (기존 하네스 중복 또는 부풀림):

| 제외 항목 | 기존 대체 |
|----------|----------|
| `/ce-setup` | `unbounded-engine` 셋업 모드 (Step 1→4) |
| `/ce-ideate` | `research-pipeline` Phase 1~2 |
| `/ce-brainstorm` | `unbounded-engine` Phase 1 메타질문 |
| `/ce-plan` | `planning-generator` (PRD/FS/IA/UF) |
| `/ce-work` | `bkit:pdca` Do phase |
| `/ce-code-review` | `/codex:review` + `harsh-critic` |
| `/ce-compound` | 본 파일 §3 실행 프로토콜 (훅 레벨 자동) |

---

## §6. 관련 문서

- `rules/accumulated-lessons.md` — 승격 후보 저장소
- `rules/asset-lifecycle.md` — `[reinforced:]` 생명주기
- `rules/daily-fit-contract.md` — Layer 3 reinforcer 동작
- `skills/retrospective-engine/SKILL.md` — 회고 → 교훈 변환
- `skills/problem-solver/SKILL.md` — Phase 2-A 3회 실패 규칙
