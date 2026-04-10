---
name: meta-harness
description: |
  메타 하네스 오케스트레이터 — 사고 스킬 7종 + 코딩 도구(g-stack/bkit) + 프로젝트 하네스 4레이어 +
  harsh-critic 품질 게이트를 하나의 파이프라인으로 연결하는 최상위 워크플로우 스킬.
  
  모든 비자명한 작업에서 "지금 어떤 단계인가?"를 자동 판단하고,
  적절한 사고 스킬 → 코딩 도구 → harsh-critic → 검증 → 회고 순서를 제안한다.
  
  ※ 다른 스킬을 대체하지 않는다. 감싸서(wrap) 올바른 순서로 호출한다.
  ※ 프로젝트의 기존 하네스(CLAUDE.md, Skills, Hooks, Agents)와 공존한다.
  ※ harsh-critic이 있으면 코딩 완료 후 자동으로 harsh-critic 체크를 삽입한다.
  
  아래 키워드 중 하나라도 포함된 요청에서 이 스킬 사용을 제안하라:
  "어떻게 진행", "뭐부터 하지", "파이프라인", "흐름", "순서",
  "전체 프로세스", "스프린트 시작", "새 기능 시작", "리팩토링 시작",
  "이거 어떤 스킬로", "뭘 써야 하지", "도구 선택",
  "한방에", "한방에 가자", "시작", "ㄱㄱ", "고", "go",
  "병렬", "워크트리", "옴니채널", "횡전개"
  
  또한 키워드가 없어도 아래 상황에서 이 스킬 사용을 제안하라:
  - 작업이 복합적이어서 여러 스킬/도구가 필요한 경우
  - 사용자가 사고 단계와 코딩 단계를 혼합하고 있는 경우
  - "한방에" 류의 트리거가 왔는데 범위가 불확실한 경우
effort: medium
user-invocable: true
---

# Meta-Harness 오케스트레이터

> 사고는 스킬이 하고, 코딩은 도구가 하며, 실수는 기록이 막는다.

## 시스템 전체 구조

```
┌──────────────────────────────────────────────────┐
│ Meta-Harness (이 스킬) — 최상위 오케스트레이터     │
├──────────────────────────────────────────────────┤
│ [사고]   7 Thinking Skills (글로벌)               │
│ [코딩]   g-stack + bkit (글로벌 플러그인)          │
│ [품질]   harsh-critic (프로젝트 품질 게이트)       │
│ [하네스] L1:CLAUDE.md L2:Skills L3:Hooks L4:Agents│
└──────────────────────────────────────────────────┘
```

## Phase 0: 작업 분류 — 애매하면 물어본다

### 제1원칙: 추측하지 않는다

```
명확한 경우 → 바로 실행
애매한 경우 → 물어본다 (최대 3개 질문)
```

"한방에"의 범위가 불확실하면 반드시 역질문:
- "어떤 작업?" (N-gram 엔진 / 차트 F1 / 데이터 파이프라인)
- "어디까지?" (Phase 1 사고만 / Phase 2 코딩까지 / 풀 루프)
- "병렬?" (워크트리 병렬 / 순차 / 해당 없음)

### 복잡도 판별

```
Q1. 한 턴에 끝나는 단순 작업? → 스킬 불필요. 직접 응답.
Q2. 사고 먼저? 코딩 먼저? 둘 다? → Phase 1/2/순차
Q3. 스프린트 계약 필요? → WALK/RUN 티어: 풀 루프
Q4. 병렬 가능? → 워크트리 / 옴니채널 / 순차
```

### 축약 경로

| 상황 | 경로 |
|------|------|
| 단순 버그 | problem-solver → 수정 → verification |
| 신규 기능 | planning → bkit PDCA → g-stack /review |
| UI 구현 | ui-ux-pro-max (--design-system) → bkit PDCA Do → visual-proof |
| 기술 결정 | unbounded → research → verification |
| 코드 리뷰 | verification → g-stack /review + /cso |
| 최적화 | research → ralph-loop → verification |
| 장애 대응 | problem-solver → 긴급 수정 → retrospective |
| 리팩토링 | unbounded → planning → bkit → g-stack → retro |
| 스프린트 시작 | planning → 스프린트 계약 → bkit PDCA |
| 스프린트 종료 | g-stack /retro → retrospective → CLAUDE.md 갱신 |
| 병렬 개발 | planning → 워크트리 분할 → 2+2 교대 → 머지 |
| 콘텐츠 횡전개 | research → planning → 원소스 → 채널 변환 |

## Phase 1: 사고 (Think First)

```
"방향이 맞나?"        → unbounded-engine
"뭘 만들지 정리"      → planning-generator
"UI 체계 결정"        → planning-generator + ui-ux-pro-max (--design-system)
"왜 안 되지?"         → problem-solver
"선례/근거 필요"      → research-pipeline
"반복 최적화"         → ralph-loop
"맞는지 확인"         → verification-pipeline
"뭘 배웠나?"          → retrospective-engine
```

규칙:
- ALWAYS: 사고 중 코드 작성 금지
- ALWAYS: 사고 결론을 코딩 도구의 입력으로 전달

## Phase 2: 코딩 (Build)

```
"UI 디자인 결정/컴포넌트 구현" → /ui-ux-pro-max --design-system → bkit PDCA Do
"새 코드 작성"                 → bkit PDCA Do
"설계-구현 괴리"               → bkit gap-detector
"코드 리뷰"                    → g-stack /review
"보안 점검"                    → g-stack /cso
"브라우저 QA"                  → g-stack /qa
"핵심 로직 이중검증"           → g-stack /codex
"PR/배포"                      → g-stack /ship
```

### 프로젝트 하네스 연동 (기존 시스템 존중)

```
1. CLAUDE.md 규칙 확인 (L1 — 최우선)
2. 프로젝트 스킬 존재 시 그것 사용 (L2 — /manual, /save 등)
3. Hook 규칙 준수 (L3 — scaffold-violation 등)
4. 적절한 에이전트 위임 (L4 — data-engineer 등)
```

### harsh-critic 연동

코딩 완료 후, harsh-critic이 프로젝트에 설치되어 있으면:

```
코드 완료 → harsh-critic 11항목 체크 (EXTREME→HIGH→MEDIUM)
  ├── BLOCK/FAIL → 자동 수정 → 재검증
  └── PASS → 사용자에게 전달
```

harsh-critic의 3단계 분노 트리거를 기억:
- EXTREME (즉시 BLOCK): 예외 지시 위반, QA 없이 완료 선언, 같은 실수 반복
- HIGH (FAIL): 사용자에게 떠넘기기, 디자인 미달, 근거 없는 규칙, 범위 누락
- MEDIUM (WARNING): 불필요 허가 요청, 기존 인프라 무시, 형식적 사과

## Phase 2-B: 워크트리 병렬 (대규모 작업)

```
① planning으로 작업 분할
② 파일 소유권 기준 워크트리 분할 (최대 4개)
③ 워크트리별 CLAUDE.md 배치 (범위 한정)
④ 2+2 교대 병렬 (30분씩, 토큰 관리)
⑤ team-lead: 순서대로 머지 → 통합 테스트
⑥ retrospective 회고
```

## Phase 2-C: 옴니채널 (콘텐츠)

```
크롤링 → research → planning → 원소스 작성
  → Threads(소재테스트) → 반응 좋은 것만 카드뉴스/쇼츠
  → ralph-loop(최적화) → retrospective(다음 주제)
```

## Phase 3: 검증 + 회고 (Verify + Learn)

```
사고 산출물 → verification-pipeline
코드 산출물 → harsh-critic → g-stack /review /cso /qa
UI 산출물  → visual-proof (채점) + ui-ux-pro-max Quick Reference (기준)
하네스 기록 → eval_log.jsonl
    ↓
retrospective-engine (DAKI)
    ↓
교훈: ALWAYS / NEVER / WHEN...THEN
    ↓
CLAUDE.md에 축적 → 다음 세션 자동 로드
```

자동 트리거:
- 테스트 3회 연속 실패 → retrospective incident
- 스프린트 종료 → retrospective sprint + g-stack /retro
- 같은 에러 2회 → unbounded 재진입
- CLAUDE.md 50+항목 → retrospective memory (정리)

## 호환성 규칙

- 프로젝트 CLAUDE.md(L1) 규칙이 항상 최우선
- 프로젝트 스킬(L2)이 있으면 코딩 도구보다 우선
- Hook(L3)은 절대 우회하지 않음
- harsh-critic이 있으면 코딩 완료 후 반드시 거침
- 에이전트(L4) 위임 시 담당 파일만 수정
- g-stack과 bkit을 같은 파일에 동시 사용 금지

## Anthropic Best Practice (2026.04 기준)

- 컨텍스트 60% 이하 유지 (점진적 공개)
- effort frontmatter로 스킬별 모델 부하 조절
- 성공은 침묵, 실패만 소리 (Hook 원칙)
- CLI > MCP (학습 데이터에 포함된 도구)
- 30분 스프린트 + /compact 리듬
- auto mode는 명시적 사용자 경계("push 금지" 등)를 존중
- 워크트리 flag가 skills/hooks를 올바르게 로드 (v2.1.50+ 수정됨)
- 자동 메모리에 타임스탬프 포함 (최신/오래된 메모리 구분)

## 자가 검증

- [ ] 애매한 부분을 추측하지 않고 물어봤는가?
- [ ] "한방에"의 범위를 확인했는가?
- [ ] 사고 단계와 코딩 단계를 분리했는가?
- [ ] 적절한 축약 경로를 선택했는가?
- [ ] 프로젝트 기존 하네스를 존중했는가?
- [ ] harsh-critic 체크를 건너뛰지 않았는가?
- [ ] 검증 단계를 건너뛰지 않았는가?
- [ ] 교훈을 ALWAYS/NEVER/WHEN...THEN으로 변환했는가?
