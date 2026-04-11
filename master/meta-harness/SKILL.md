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

### 축약 경로 (meta-eval 2026-04-11 최적화 반영)

> 원칙: 마스터=사고 프레임워크(WHAT), 플러그인=실행 자동화(HOW).
> 같은 단계에서 둘 다 돌리면 토큰 낭비. 순차(사고→실행)로 연결.
> 교차검증이 필요하면 /codex 사용 (다른 모델 관점).
> Codex 3모드: review(diff 리뷰), adversarial-review(설계 도전), rescue(위임).

| 상황 | 경로 | 역할 분담 |
|------|------|-----------|
| 코드 버그 | problem-solver → 수정 → qa | 마스터가 진단, 플러그인이 검증 |
| 코드 버그 (교착) | problem-solver 3회 실패 → /codex:rescue --background | GPT에 위임 (비동기) |
| 비코드 문제 | problem-solver → 수정 → verification | 마스터 단독 (investigate 불필요) |
| 신규 기능 | office-hours(검증) → planning(문서) → autoplan(리뷰) → bkit PDCA(실행) → review → ship | Z1 순차: 아이디어→문서→검증→실행 |
| UI 신규 설계 | office-hours → plan-ceo-review → design-consultation → design-shotgun → ui-ux-pro-max → design-html → design-review → visual-proof | 플러그인 독점 |
| UI 기존 개선 | design-review → ui-ux-pro-max → design-html → visual-proof | 플러그인 독점 |
| 컴포넌트 구현 | ui-ux-pro-max (--design-system) → bkit PDCA Do → design-review → visual-proof | 플러그인 독점 |
| 기술 결정 | unbounded → research → verification | 마스터 체인 |
| 코드 리뷰 | review → cso → health | 플러그인 독점 |
| 코드 리뷰 (교차) | review → /codex review(GPT 독립 리뷰) → 양쪽 비교 | Claude+GPT 이중검증 |
| QA/검증 | verification(게이트 설정) → qa + full-verify(실행) → health(대시보드) | Z3: 마스터=프레임워크, 플러그인=실행 |
| 보안 점검 | cso → full-verify | 플러그인 독점 |
| 최적화 | ralph-strategy(전략) → ralph-loop(루프 실행) → verification(판정) | Z6: 마스터=전략, 플러그인=실행 |
| 장애 대응 | careful/guard ON → problem-solver → 긴급 수정 → retrospective-engine | 마스터 단독 |
| 리팩토링 | unbounded → planning → bkit PDCA → review → health → retro(데이터) → retrospective-engine(분석) | Z4: 플러그인=데이터, 마스터=분석 |
| 기획 전체 리뷰 | planning(문서 생성) → autoplan(4개 리뷰 자동 순차) | Z1: 마스터 생산 → 플러그인 검증 |
| 기획 검토 (선택) | office-hours → plan-ceo/design/eng/devex-review | 플러그인 독점 |
| 스프린트 시작 | sprint-start → planning → 스프린트 계약 → bkit PDCA | 마스터→플러그인 순차 |
| 스프린트 종료 | retro(데이터 수집) → retrospective-engine(분석+메모리) → CLAUDE.md 갱신 | Z4 순차 |
| 배포 준비 | verification(게이트) → full-verify + review + cso(실행) → ship | Z3 순차 |
| 배포 실행 | land-and-deploy → canary | 플러그인 독점 |
| 배포 후 | document-release → health | 플러그인 독점 |
| 세션 중단/재개 | checkpoint (저장) → checkpoint resume (복구) | 플러그인 독점 |
| 파괴적 작업 전 | careful 또는 guard (파괴적 명령 감시) | 플러그인 독점 |
| 병렬 개발 | planning → 워크트리 분할 → 2+2 교대 → review → 머지 | 혼합 |
| 콘텐츠 횡전개 | research → planning → 원소스 → 채널 변환 | 마스터 체인 |
| 아이디어 검증 | office-hours → plan-ceo-review → research → verification | 플러그인→마스터 순차 |
| DX/API 설계 | plan-devex-review → plan-eng-review → verification | 플러그인→마스터 순차 |
| 근본적 재고 | unbounded (독점) — office-hours와 겹치지 않음 | 마스터 독점 |
| 브라우저 자동화 | /browse (headless Chromium, playwright MCP 대체) | 플러그인 독점 |
| 스킬 충돌 평가 | /meta-eval (마스터 vs 플러그인 벤치마크) | 마스터 독점 |

## Phase 1: 사고 (Think First)

```
"방향이 맞나?"         → unbounded-engine
"뭘 만들지 정리"       → planning-generator
"UI 체계 결정"         → planning-generator + ui-ux-pro-max (--design-system)
"왜 안 되지?"          → problem-solver
"선례/근거 필요"       → research-pipeline
"반복 최적화 전략"     → ralph-strategy → ralph-loop
"맞는지 확인"          → verification-pipeline
"뭘 배웠나?"           → retrospective-engine
"아이디어 검증"        → office-hours (YC 스타일 6개 강제 질문)
"기획 전략 검토"       → plan-ceo-review (전략) + plan-design-review (설계)
"엔지니어링 검토"      → plan-eng-review (아키텍처) + plan-devex-review (DX)
"전체 기획 자동검토"   → autoplan (4개 리뷰 순차 자동 실행)
```

규칙:
- ALWAYS: 사고 중 코드 작성 금지
- ALWAYS: 사고 결론을 코딩 도구의 입력으로 전달

## Phase 2: 코딩 (Build)

```
"UI 디자인 결정/컴포넌트 구현" → ui-ux-pro-max --design-system → bkit PDCA Do
"새 코드 작성"                 → bkit PDCA Do
"설계-구현 괴리"               → bkit gap-detector
"코드 리뷰"                    → review (PR 착륙 전) → cso (보안)
"코드 품질 진단"               → health (0-10 점수)
"보안 점검"                    → cso (OWASP, STRIDE, secrets 스캔)
"브라우저 QA/스크린샷/자동화"  → /browse (headless Chromium, playwright MCP 대체)
"전체 배포 전 검증"            → full-verify (빌드+린트+타입+보안+e2e)
"핵심 로직 이중검증"           → /codex review (diff 기반 독립 리뷰, Pass/Fail)
"설계 접근 자체 도전"          → /codex adversarial-review (접근법이 맞는지 챌린지)
"디버깅/구현 교착"             → /codex:rescue (Codex에 작업 통째 위임, --background 가능)
"PR/배포"                      → ship (VERSION 범프 + PR) 또는 land-and-deploy (머지+CI+배포)
"배포 후 모니터링"             → canary
"배포 후 문서"                 → document-release
"버그 근본원인"                → investigate (체계적 추적 → 가설 → 수정)
"안전 가드레일"                → careful (파괴적 명령 경고) 또는 guard (careful + freeze)
"세션 상태 저장"               → checkpoint
"배포 설정"                    → setup-deploy (Fly/Render/Vercel/Netlify 자동 감지)

> **브라우저 자동화**: playwright MCP는 전역에서 제거됨.
> 브라우저가 필요한 모든 작업(QA, 스크린샷, 폼 테스트, 사이트 검증)은 `/browse` 사용.
> `/browse`는 gstack 내장 headless Chromium으로 playwright MCP와 동일 기능 제공.
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

## Phase 2-D: UI/UX 설계 파이프라인

```
① 새 UI 설계 시작
   office-hours (YC 스타일 검증 6문) → plan-ceo-review (전략 적합성)
   → design-consultation (경쟁사 조사 + 디자인 시스템 제안)
   → design-shotgun (복수 시안 생성 + 비교)
   → ui-ux-pro-max (67스타일/161팔레트 기준 최종 선택)
   → design-html (HTML/CSS 변환)
   → design-review (라이브 감시: 간격/계층/AI slop)
   → visual-proof (4신호 자동 검증 + 채점)

② 기존 UI 개선
   design-review (현황 감사) → ui-ux-pro-max (개선 기준) → design-html → visual-proof

③ 빠른 컴포넌트 추가
   ui-ux-pro-max (--design-system 모드) → bkit PDCA Do → design-review
```

## Phase 2-E: QA + 배포 파이프라인

```
① 배포 전 검증
   health (코드 품질 0-10) → full-verify (빌드+린트+타입+보안+e2e)
   → review (PR 코드 리뷰) → cso (보안 감사)
   → ship (VERSION 범프 + PR 생성) 또는 land-and-deploy (자동 머지+CI+배포)

② 배포 후 확인
   canary (라이브 모니터링) → document-release (문서 동기화)

③ QA 전용
   browse (헤드리스 브라우저) → qa (버그 발견+수정) → qa-only (감사 보고서만)
   → cso (보안 포함 전체 감사)

④ 버그 추적
   investigate (체계적 근본원인) → problem-solver (해결 계획) → health (재확인)
```

## Phase 2-F: 스프린트 관리 파이프라인

```
① 스프린트 시작 (harness fit 포함)
   bash ~/.claude/skills/harness-fit.sh  ← gstack/bkit/pretext 자동 업데이트
   → sprint-start (이전 교훈 확인 + 메타질문 + 계획 계약)
   → planning (기능 분해) → bkit PDCA

② 세션 중
   checkpoint (30분마다 저장 권장)
   careful/guard (프로덕션 변경 전 자동 활성)

③ 스프린트 종료
   retro (커밋 히스토리 + 기여도) → retrospective-engine (DAKI) → CLAUDE.md 갱신
```

### harness-fit 업데이트 대상

| 컴포넌트 | 업데이트 방법 |
|---------|-------------|
| gstack | git pull + /gstack-upgrade |
| bkit | claude plugin update bkit |
| pretext vendor | npm install @chenglou/pretext@latest + esbuild 재빌드 |
| ralph-loop | claude plugin update ralph-loop |
| skill-creator | claude plugin update skill-creator |

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
- 테스트 3회 연속 실패 → investigate → retrospective incident
- 스프린트 종료 → retro → retrospective-engine → CLAUDE.md 갱신
- 같은 에러 2회 → unbounded 재진입
- 배포 명령 감지 → careful/guard 자동 활성
- 코드 완료 직후 → health → review → cso (순서대로)
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
