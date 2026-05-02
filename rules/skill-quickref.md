<!-- last-updated: 26/04/20 -->
---
description: 54+ 스킬 1페이지 퀵레퍼런스 — 키워드→스킬 매핑으로 ORCH 축 강화
paths:
  - "**/*"
---

# Skill Quick Reference

> 54+ 스킬은 description 키워드로 자동 트리거. 어떤 키워드가 어떤 스킬을 부르는지 1분 안에 찾기.

> **Auto Mode 운영중**: `settings.json` `defaultMode: "auto"` + `skipDangerousModePermissionPrompt: true` 활성. 안전 작업은 무중단, 데이터 삭제·공유 시스템 변경만 컨센트. (출처: `rules/anthropic-blog-may2026.md §4`)

## 6 카테고리 × 주요 스킬

### 🎯 기획 (Plan)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **planning-generator** | 기획, 계획, PRD, 뭘 만들지, 어떻게 접근 | PRD→FS→IA→UF 4단계 + Phase 1-D 마이크로태스크 |
| unbounded-engine | 방향, 진짜 문제, 처음부터, 재정의 | 메타질문 — "이게 진짜 문제인가?" |
| research-pipeline | 조사, 선례, 비교, 라이브러리 선택 | Phase 1-8 체계적 리서치 |

### ⚡ 실행 (Do)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **problem-solver** | 왜 안 되지, 버그, 근본 원인, 디버깅 | Phase 2-A 4단계(조사→패턴→가설→구현). **3회 실패 시 unbounded 재진입** |
| ralph-strategy | 반복, 자동 최적화, 파라미터 탐색 | 자율 반복 루프 |
| bkit:pdca | 기능 구현, PM→PLAN→DESIGN→DO→CHECK→REPORT | bkit 6단계 PDCA |

### ✅ 검증 (Check)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **/verify** | 방금 수정, 차트 고쳤어, 이거 됐나, 고친 거 확인, 자가검증, 코드 변경 직후, 에이전틱 루프, just edited, did it work | 코드 수정 직후 L0~L5 자동분류 + FAIL 시 자가수정 루프(3회). **L0~L4 자동, L5(서브에이전트)만 사용자 컨센트** |
| verification-pipeline | 배포 전 검증, Go/No-Go, 한방에 검증 | 전체 검증 파이프라인 (대규모) |
| cso | 보안, 취약점, RLS, 인증 | 보안 감사 (opus) |
| review / codex:rescue | 리뷰, PR 전 검토 | /review + /codex 교차검증 |
| **drift-sentinel** | drift, breaking change, OpenAPI diff, CPCV, 설계 이탈 | PostToolUse 경량 drift 감지 + fit-escalation 매핑 |
| **traceability-weaver** | 추적성, REQ-ID, orphan, E2E trace, 매트릭스 | REQ ID 자동 연쇄 추적 (prompt→code→commit) |

### 🔄 회고 (Act)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **retrospective-engine** | 회고, retro, KPT, 돌아보자, 교훈 | 5유형(M/S/P/I/C) + Phase 1.7 스킬 후보 제안 |
| meta-eval | 스킬 평가, 하네스 건강도 | 스킬 자체 평가 |

### 🧠 메타 (Meta)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| meta-harness | 하네스 상태, 흐름 확인 | 마스터 인덱스 |
| simplify | 단순화, 중복 제거, 품질 | 코드 리뷰 + 간소화 |

### 🛠 도구 (Tool)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| codex:* | GPT 검증, 적대적 리뷰 | Codex 플러그인 |
| **/loop** | 인터벌 자율 반복, 5분마다, 폴링, 모니터링 light | `/loop 5m /your-cmd` 또는 자기 페이스. 기록·상한 빈약 → 무거운 반복은 ralph-strategy 우선. interval ≥5m 권장. (출처: `anthropic-blog-may2026.md §8`) |
| gstack | g-stack 프로젝트, `$B` 명령, browse 실행기 | g-stack 전용 + `browse/dist/browse` 바이너리 원천(모든 browse 계열의 런타임) |
| **browse** | 브라우저 자동화, headless, 스크린샷, snapshot, E2E, `@e`/`@c` refs, chain, diff, 클릭/입력 자동화 | 기능 E2E 기본 스킬 — Playwright/CDP 래퍼. navigate/click/fill/screenshot/snapshot/chain/responsive/state assertion. headless 기본(~100ms/cmd) |
| **connect-chrome** | 실제 Chrome 연결, headed 모드, side panel, 로그인 세션 유지, CAPTCHA, MFA, handoff | Playwright 번들 Chromium + gstack extension(port 34567) + 사이드바 child agent. 수동 개입 구간 `$B handoff`/`$B resume` |
| **setup-browser-cookies** | 쿠키 임포트, 로그인 상태 복원, cookie-import-browser | 설치된 Chromium 변종 자동 감지 → 도메인 선택 UI로 쿠키 임포트 |
| bkit:* | b-kit, PDCA, 엔터프라이즈 | b-kit 전용 |
| less-permission-prompts | 승인 프롬프트 줄이기 | allowlist 자동 생성 |
| **ux-rehearsal** | UX 리허설, 페르소나, 받는 사람 관점, ux-rehearse | 3 페르소나 5축 채점 (<70 → harsh-critic) |
| **observability-bus** | observability, OTel, 주간 이벤트, obs.jsonl | 3축 JSONL 집계·rotate·리포트 |
| **ui-ux-pro-max** (refs) | 토스 스타일, apps-in-toss, Apps in Toss, RN 앱, 원티드, Wanted Design, Wanted Sans, Montage, 한국향 UI | Toss 24예제 + Wanted 40토큰 글로벌 참조 (`--refs` 체인 조회) |

---

## 병목 발생 시 스킬 선택 플로우

```
뭐가 막힘? 🤔
├── 같은 에러 2회+ → problem-solver (Phase 2-A 철칙)
├── 3배 시간 초과 → unbounded-engine (문제 재정의)
├── 방향 자체 모호 → unbounded-engine + research-pipeline
├── 컨텍스트 60%+ → /compact + 핵심 제약 재주입
├── 도구 선택 불명 → 이 파일(skill-quickref.md) 재참조
└── 모델 한계 → model-strategy.md 에스컬레이션
```

참조: `rules/auto-triggers.md` 병목 섹션, `rules/thinking-flow.md`, `rules/model-strategy.md`

---

## 다중 에이전트 패턴 (빠른 선택)

| 패턴 | 트리거 | 파일 |
|------|--------|------|
| Orchestrator/Swarm/Pipeline/Review/Fan-out | 복잡 작업 조율, 병렬 서브에이전트 | `rules/multi-agent-patterns.md` |
| Advisor (Sonnet + Opus 단일 턴) | 구현+판단 동시, sonnet 2회 실패 후 3.5차 | `rules/advisor-strategy.md` |

> **결정 매트릭스 (v2.1 신규)**: `multi-agent-patterns.md §결정 매트릭스` 4종 표 — 작업 유형 / 위험도 / 컨텍스트 사용량 / R1 트레이딩 격리. *언제 어떤 패턴*을 결정론적으로 선택.

---

## 한방 진입점 (autopus `/auto dev` 패턴 차용)

> **자동 우선**: `~/.claude/hooks/oneshot-trigger.sh` (UserPromptSubmit)가 자연어 키워드 자동 감지.
> 수동 슬래시는 fallback. 사용자는 평소처럼 자연어로 말하면 됨.

| 진입점 | 자동 트리거 키워드 | 용도 |
|--------|------------------|------|
| `/oneshot dev`    | "한방에 개발", "처음부터 끝까지 만들어", "전부 알아서 해" | 사고→구현→검증→회고 6레이어 자율 |
| `/oneshot verify` | "한방에 검증", "배포 전 완전 검증", "출시 전 검증" | 6축 동시 검증 + 자동 수정 |
| `/oneshot advise` | "조언해줘", "갈림길", "판단이 안 서", "사각지대" | 5인 자문위원회 (비실행) |
| `/oneshot setup`  | "하네스 핏", "harness fit", "CLAUDE.md 생성" | 하네스 핏 (4 Step) |

---

## On-Demand 참조 문서 (자동 로드 안 됨 — 필요 시 명시적 Read)

| 문서 | 키워드 / 언제 | 경로 |
|------|--------------|------|
| 다중 에이전트 패턴 | multi-agent, Orchestrator, Swarm, Fan-out, Debate | `rules/multi-agent-patterns.md` |
| Advisor 전략 | Advisor, Sonnet+Opus, 3.5차 에스컬레이션 | `rules/advisor-strategy.md` |
| Compound 원칙 | compound, 복리 엔지니어링, 회고 후 강화 | `rules/compound-principle.md` |
| MemPalace 워크플로 | mempalace, 실수 기록, 성장 일지, 회고 동기화 | `rules/mempalace-workflow.md` |
| Anthropic Blog 요약 | Advisor 근거, 서브에이전트 베스트프랙티스 | `rules/anthropic-blog-apr2026.md` |

---

## v3 검증 자산 (2605010914)

| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **test-process** | 테스트 계획 / 테스트 어떻게 / 테스트 전략 짜줘 / TC 작성 | ISO 29119 5-Activity 플랜 |
| **test-design** | TC 만들어 / 동등 분할 / 경계값 / 페어와이즈 / 결정 테이블 | ISTQB 5기법 자동 적용 |
| **vv-separator** | 의도대로 됐어? / 내가 원한대로 / 의도 검증 / validation | V-모델 Validation (fresh subagent). backtest_engine.py 자동 SKIP |
| **coverage-gate** | 커버리지 / 분기 커버 / coverage 부족 | 분기 커버리지 게이트 (A 95% / 일반 80%). backtest_engine.py SKIP |
| **mutation-test** | 변형 테스트 / mutation / 테스트가 잡나 | 자금 직결 mutation_score ≥ 80% |
| **fuzz-test** | fuzz / 퍼즈 / property test / 랜덤 입력 | Hypothesis property-based + 선별 fuzz |
| **llm-eval-suite** | eval / 프롬프트 평가 / 스킬 회귀 | 50+ prompt × 3 seed, 일일 5 USD cap |
| **multi-judge** | 다중 심사 / judge ensemble / 교차 검증 LLM | 3-judge majority vote (J1+J3 기본) |
| **trajectory-tracker** | 추적 / trajectory / replay / 이전 작업 분석 | 로컬 JSONL observability |
| **deb-bundler** | (자동 호출) / DEB / 자세히 / 근거 | DEB 표준 보고 (light/full) |
| **trading-safety-tester** | trading safety / 거래 안전 / Order idempotency / Kill-switch SLA | 자금 직결 4종 안전 검증 (P0) |

---

## v4 코딩·의사결정·자가발전 자산 (2605011041)

### 코딩 1순위 (Wave D)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **plan-mode-router** | 계획 먼저 / Opus plan / spec-driven / 플랜 짜고 구현 | Opus Plan + Sonnet Impl 자동 분리. backtest_engine.py SKIP |
| **spec-driven-coder** | spec 먼저 / TDD / 계약 먼저 / 인터페이스 먼저 | docstring+TC 먼저, 구현 나중 |
| **coding-eval-suite** | 코드 품질 점수 / 구현 평가 / 5축 평가 | 정확성/가독성/성능/보안/커버리지 채점 |
| **skills-v2-migrator** | 스킬 업그레이드 / frontmatter 없는 스킬 / v2 표준 | SKILL.md v2 표준화 일괄 정비 |
| **coding-pattern-library** | 재사용 패턴 / 안티패턴 / 우리 프로젝트 패턴 | GO v2 + 하네스 패턴 카탈로그 |
| **coding-confidence-tracker** | 신뢰도 / 예측 / 구현 확신 | 구현 전 예측 → 실제 결과 Brier score |
| **coding-decision-journal** | ADR / 왜 이렇게 / 아키텍처 결정 기록 | 결정 근거 structured log + lore-commit 연동 |
| **dora-reporter** | DORA / 배포 빈도 / 변경 실패율 / 리드타임 | git 기반 DORA 4 메트릭 월간 리포트 |

### 의사결정 메타인지 (Wave E)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **decision-helper** | 갈림길 / 선택 / 어떻게 결정 / 판단이 안 서 | 의사결정 마스터 — Cynefin 분류 후 프레임 선택 |
| **pre-mortem** | 사전 부검 / 이게 실패하면 / 위험 예측 / Klein | "이미 실패" 역추론으로 위험 탐지. R1 트레이딩 제외 |
| **wrap-decision** | 시야 확장 / 10/10/10 / 현명한 친구 / 이항 대립 | Heath 래핑 3기법으로 좁은 프레임 확장 |
| **sdg-6-elements** | SDG 6요소 / Frame Alternatives Logic Commitment | Stanford SDG 약한 고리 식별 + 라우팅 |
| **confidence-calibration** | Brier / 과신 편향 / 캘리브레이션 / 예측 정확도 | Tetlock Brier score로 확신 품질 측정 |
| **devils-advocate** | 반론 / 악마의 변호인 / 편향 제거 / 확증 편향 | 의도적 반론 3각도. 10% 샘플 트리거 |
| **double-loop-quarterly** | 이중루프 / governing variable / 근본 가정 / 분기 회고 | Argyris double-loop. 분기 1회, 사용자 선택 (R8) |
| **metacognitive-monitor** | 메타인지 / 사고 편향 / 내가 제대로 생각하고 있나 | 확증 편향/과신/터널비전 실시간 감지 |

### 자가발전 (Wave C)
| 스킬 | 트리거 키워드 | 용도 |
|------|-------------|------|
| **auto-mutation-pipeline** | 자가발전 / 하네스 진화 / DNA 변이 / staging | staging area 경유 변이 제안. 사용자 OK 필수 |
