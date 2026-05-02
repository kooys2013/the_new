---
paths:
  - "__on_demand_only__"
---
# 자동 트리거 규칙

## 기존 (유지)
- 테스트 3회 연속 실패 → retrospective-engine incident
- 스프린트 종료 → retrospective-engine + g-stack /retro
- 같은 에러 2회 반복 → unbounded-engine 재진입
- CLAUDE.md 50+ 항목 → retrospective-engine memory (정리)

## /verify 자가검증 자동 트리거 (v2.8 — 자연 발동 환경 조성)
<!-- origin: feedback_verify_natural_invocation + feedback_verify_ask_before_invoke | merged: 26/05/01 -->
- WHEN: 사용자 발화에 "방금 수정", "차트 고쳤어", "코드 고쳤어", "이거 됐나", "고친 거 확인", "방금 패치", "잘 됐는지", "just edited", "did it work" 포함 THEN: **/verify 우선 매칭** (verification-pipeline 보다 먼저)
- WHEN: PostToolUse Edit/Write/MultiEdit로 5+줄 코드 변경 + 직후 사용자 발화에 "수정/고침/됐나/확인" 포함 THEN: /verify 진입 — L0~L4(skip/훅/pytest/스크린샷/E2E) 자동, **L5(서브에이전트, 0.05~5 USD)만 사용자에게 "verify L5로 심층 검증할까요? (예상 비용 ~X USD)" 컨센트 후 진입**
- WHEN: 코드 변경 직후 SCP-5 검증연극 패턴(검증 흔적 부재) 감지 THEN: 다음 턴 시작 시 /verify 자가검증 자동 진입 권고
- ALWAYS: /verify와 verification-pipeline 키워드 충돌 시 → 매칭 우선순위 = /verify(코드 수정 직후 경량) > verification-pipeline(배포 전 종합)

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

## 플랜 모드 × planning-generator 연결 (v2.6)
- WHEN: ExitPlanMode 호출 직후 THEN: 메인 스레드가 plan 파일 구조 점검 → PRD/FS/IA/UF 4섹션 없으면 planning-generator 프레임으로 재구조화 제안 (Phase 1-D 마이크로태스크 포함)

## 리뷰 시 plan 파일을 design-intent oracle로 사용 (v2.7.1)
<!-- origin: mafia-codereview-harness design-intent pattern | merged: 26/04/26 -->
- WHEN: `/review` / `/codex:review` 호출 시점에 `~/.claude/plans/*.md` 또는 `docs/01-plan/*.md` 존재 THEN: 리뷰어는 plan 파일에 명시된 *의도된 결정*에 대해 "왜 이렇게?" 질문 금지 — 의도-구현 *불일치*만 지적
- WHEN: plan 파일에 명시되지 않은 비표준 패턴 발견 THEN: 정상적으로 지적
- ALWAYS: 리뷰 코멘트에서 plan 파일 라인 인용 시 `plan:LXX` 형식
- 파일 미존재 시: 기존 동작 유지 (역호환)

## 병목 감지 + 즉시 대응 트리거 (v2.6)

> "속도가 안 나올 때" → 수정 전 반드시 병목 유형 진단 먼저

| 감지 신호 | 강제 대응 | 근거 |
|----------|----------|------|
| 같은 파일/함수에서 2회 연속 수정 실패 | **problem-solver Phase 2-A 강제 진입** (근본원인 미확인 시 수정 금지) | SCP-5 + [SCP-3] |
| 동일 에러 메시지 2회 이상 등장 | 수정 금지 → 4단계 진단 (조사→패턴→가설검증→구현) 먼저 | Phase 2-A 철칙 |
| 작업 소요 시간이 예상의 3배 초과 | **unbounded-engine 재진입** — 문제 재정의 (방향 자체 점검) | SCP-3 복잡도회피 |
| 컨텍스트 60% 초과 + 작업 진행 중 | **/compact 즉시** + 핵심 제약 3줄 재주입 후 재개 | SCP-2 컨텍스트열화 |
| 3회 이상 실패 후 "일단 해보자" 충동 | **중단** → problem-solver Phase 2-A 3회실패 에스컬레이션 경로 | Phase 2-A 3회규칙 |

### 병목 진단 5초 루틴

```
"지금 왜 느린가?" 자문:
1. 에러 메시지가 같은가? → Phase 2-A (근본원인)
2. 파일 구조가 머릿속에 없는가? → /compact + Explore agent
3. 방향 자체가 맞는지 모르겠는가? → unbounded-engine
4. 도구를 잘못 쓰고 있는가? → tool-routing.md 참조
5. 모델 한계인가? → model-strategy 에스컬레이션
```

<!-- origin: bottleneck-response-system | merged: 26/04/17 -->

## Self-Evolving System 트리거 (DNA 진화)

### 교훈 → 규칙 자동 승격 파이프라인
- WHEN: accumulated-lessons.md에 같은 ALWAYS/NEVER 3회+ 축적
  THEN: rules/ 승격 후보 제안 (retrospective-engine Phase 4.5 졸업 판정과 연동)
- WHEN: rules/ 규칙 위반 2회+ 반복
  THEN: hooks/ 강제화 후보 제안
- WHEN: hooks/ 훅이 6개월간 위반 0회
  THEN: 내면화 완료 → archive 제안

### DNA 진화 트리거 (세션 종료 시)
- WHEN: harsh-critic EXTREME 위반 발생한 세션
  THEN: retrospective-engine 필수 실행 + SCP 분류 + 규칙 mutation 제안
- WHEN: SCP-N 태그가 3세션 연속 동일 유형
  THEN: 해당 SCP 방어 로직 강화 제안 + unbounded-engine 재진입 검토
- WHEN: trend-harvester가 스택 변경 감지
  THEN: 영향받는 rules/ 파일 업데이트 제안

### 신뢰도 감쇠 (Confidence Decay)
- WHEN: accumulated-lessons.md 항목이 90일간 참조/강화 없음
  THEN: [STALE] 태그 부여 + 월간 정리 시 아카이브 후보

## dory-knowledge 자동 트리거 (v1.0)
- WHEN: 전략 카드(P/S/MP/MS/DK) 작업 시작
  THEN: search_principle("{카드 원천 원리}") 1회 호출
- WHEN: SL/TP/진입조건 파라미터 변경
  THEN: search_dory("{파라미터} 기준") 호출 + 도리님 렌즈 판정
- WHEN: 백테스트 결과 분석 단계
  THEN: search_dory("백테스트") + search_principle("등배원리") 호출
- WHEN: Phase A/B 보고서 작성
  THEN: search_dory("Phase A 검증") 호출

## Advisor 자동 트리거 (v2.7)
<!-- origin: claude.com/blog/the-advisor-strategy | merged: 26/04/17 -->
- WHEN: sonnet 2회 실패 + 판단 지점(아키텍처/보안/설계) 포함 THEN: **Advisor 호출 (3.5차)** — opus 전면 전환 전 저비용 시도
- WHEN: 구현 + 아키텍처 결정 동시 필요 THEN: Advisor 제안 (`rules/advisor-strategy.md §4`)
- WHEN: 사용량 ORANGE/RED THEN: Advisor 자제/금지 (Opus 토큰 과다 소비)

## Codex 자동 트리거 (공식 플러그인 v2.1 — 자동화 강화)
<!-- updated: 26/04/18 — background 마커, --resume, --scope, spark 모델 반영 -->

### 자동 (Stop hook 연동 — stop-codex-bg.sh)
- WHEN: 세션 종료 + 코드 파일 변경 감지 THEN: `_cache/codex-review-pending.json` 마커 생성
  → 다음 SessionStart briefing에서 자동 노출 + 추천 커맨드 표시
- WHEN: 민감 파일(auth/rls/sql/security/schema) 변경 감지 THEN: `adversarial` 마커 → briefing에서 `/codex:adversarial-review --scope working-tree` 권고
- WHEN: 일반 코드 변경 감지 THEN: `review` 마커 → briefing에서 `/codex:review --model spark --effort low` 권고

### 🔥 완전 자동 (stop-codex-bg.sh 백그라운드 실행 — v2.7)
- WHEN: Stop 훅 + 코드 파일 변경 감지 THEN: **`node codex-companion.mjs review` 자동 실행**
  - 일반 코드 → `review --scope working-tree` (기본 모델 gpt-5.4)
  - 민감 파일(auth/rls/sql/schema 등) → `adversarial-review --scope working-tree`
  - 참고: ChatGPT 계정은 `spark` 모델 미지원 — 기본 모델 사용 (Plus 40min/5h 쿼터)
  - bash `nohup ... & disown` 으로 detach, Stop 훅 < 100ms 반환
  - 하드 타임아웃 900s
- WHEN: SessionStart briefing에 `[CODEX-AUTO] ✅ 완료` 표시 THEN: **Claude `/review` 호출 금지** (동일 diff 중복 리뷰 = 토큰 낭비)
  - 결과 확인만 필요: `/codex:result <job-id>`
- WHEN: `[CODEX-AUTO] ⏳ 진행중` THEN: Codex 완료 대기, `/review` 중복 금지
- WHEN: `[CODEX-AUTO] ❌ 실패` THEN: Claude가 실패 근거(쿼터/네트워크/binary) 분석 후 수동 `/codex:review` 재시도
- 비활성화: `CODEX_AUTO_SKIP=1` 환경변수
- **절대 자동 금지**: `task --write`, `rescue` (코드 쓰기) — 리뷰 명령만 자동

### 반자동 (세션 내 트리거)
- WHEN: PR 생성 직전 THEN: `/codex:review --base main` 실행 (g-stack /review 교차검증)
- WHEN: problem-solver 2회 실패 THEN: `/codex:rescue --resume` 시도 (기존 스레드 재개) → 없으면 `/codex:rescue` (fresh)
- WHEN: 아키텍처·전략 결정 THEN: `/codex:adversarial-review --scope branch` 제안
- WHEN: 인증/보안 코드 변경 THEN: `/cso` + `/codex:adversarial-review --scope working-tree` 병행
- WHEN: 백그라운드 잡 대기 중 (briefing 노출) THEN: 세션 시작 시 `/codex:status` → 완료 시 `/codex:result` 회수

### GO 백테스트 e2e 트리거 (도메인 특화)
- WHEN: `backend/engine/*.py` 수정 완료 THEN: `/codex:review --model spark` 자동 제안 — lookahead·복리 오류 탐지
- WHEN: `backend/scripts/run_*.py` 신규·수정 완료 THEN: `/codex:review --model spark` 자동 제안 — KS 간섭·OOS 누출 점검
- WHEN: 레버리지·슬리피지·비용 계산 로직 변경 THEN: `/codex:review` — e2e 수치 오염 탐지
- WHEN: 인수인계서(handover.md) 작성 전 THEN: `/codex:review` 제안 — 논리 일관성 교차검증
- WHEN: 백테스트 Phase 완료(Stage 판정) THEN: `/codex:adversarial-review --scope branch` 제안 — 결과 해석 챌린지

### model + effort 선택 (쿼터 보호)
- 루틴 리뷰 (briefing 자동) → `--model spark --effort low` (쿼터 최소)
- PR 전 브랜치 리뷰 → 기본 모델 `--effort medium`
- 아키텍처/보안 심층 → 기본 모델 `--effort high`
- 교착 rescue → 기본 모델 `--effort xhigh`

## 리뷰 게이트 규칙 (--enable-review-gate)
- NEVER: 무인 세션에서 리뷰 게이트 활성화 (Claude↔Codex 루프 → 사용량 급소모)
- WHEN: 리뷰 게이트 활성화 THEN: 30분 제한 + 유인 감시 필수
- WHEN: 리뷰 게이트 3회+ 반복 차단 THEN: 즉시 비활성화 (`/codex:setup --disable-review-gate`)

## dory-knowledge 호출 금지 상황
- 단순 코드 구현 (UI, API, DB 스키마 — 원리와 무관)
- KORENO 업무 / 하네스 설정 / 일반 기술 리서치
- 같은 세션에서 같은 쿼리로 이미 검색한 경우

## 3축 관찰 자동 트리거 (v2.7 — E2E·UX·Drift)
<!-- origin: 3-axis-observability | merged: 26/04/18 -->
- WHEN: 사용자 프롬프트에 `(REQ|GO|KORENO)-\d{3,}` 포함 THEN: `requirement-id-tagger.sh` 자동 주입 → `traceability-weaver` 힌트
- WHEN: `.yaml` OpenAPI 파일 수정 THEN: `drift-sentinel.sh` sha256 변경 감지 → `/skill drift-sentinel` 필요 시 제안
- WHEN: GO v2 `backend/engine/*.py` 또는 `backend/scripts/run_*.py` 수정 THEN: drift-sentinel이 CPCV 재검증 권고 statusMessage
- WHEN: 세션 종료 + `*-generator` 스킬 호출 이력 THEN: `ux-rehearsal-suggest.sh` → `/skill ux-rehearsal` 권고
- WHEN: "추적성", "traceability", "REQ-ID", "E2E trace" 키워드 THEN: `/skill traceability-weaver`
- WHEN: "drift", "fitness function", "breaking change", "CPCV" 키워드 THEN: `/skill drift-sentinel`
- WHEN: "UX 리허설", "페르소나", "사용자 관점", "ux-rehearse" 키워드 THEN: `/skill ux-rehearsal`
- WHEN: "observability", "OTel", "주간 이벤트", "obs.jsonl" 키워드 THEN: `/skill observability-bus`

## Knowledge Drawer 자동 트리거 (26/04/18 — GBrain 이식)
<!-- origin: garrytan/gbrain@compiled-truth | merged: 26/04/18 -->
- WHEN: 전략 카드(P/S/MP/MS/DK) 작업 시작
  THEN: `mempalace_search "{카드명}" --wing wing_knowledge` 1회 호출
- WHEN: PSM 12요소 또는 KORENO 법규 관련 업무 시작
  THEN: `mempalace_search "PSM" --wing wing_knowledge` 호출
- WHEN: 횡전개 사이드 프로젝트 공유 인프라 결정
  THEN: `mempalace_search "횡전개 인프라" --wing wing_knowledge` 호출
- WHEN: 하네스 rules/ 수정 시작
  THEN: `mempalace_search "harness {주제}" --wing wing_knowledge` 호출
- WHEN: Stale drawer 3건+ 감지 (stale-detector 실행 결과)
  THEN: 해당 drawer 재작성 or supersedes 체인 확인 권장 알림
- WHEN: Compiled Truth 재작성 발생
  THEN: last_compiled 갱신 확인 + 타임라인에 재작성 사유 1줄 append

## UI 외부 참조 자동 트리거 (26/04/19 — Toss + Wanted 통합)
- WHEN: 프롬프트에 "토스 스타일", "apps-in-toss", "Apps in Toss", "RN 앱 참고", "토스 UI" 포함
  THEN: ui-ux-pro-max SKILL 자동 호출 + `python scripts/search.py "<query>" --refs` 조회 제안
- WHEN: 프롬프트에 "원티드", "Wanted Design", "Wanted Sans", "Montage", "wds-theme", "한국향 UI" 포함
  THEN: ui-ux-pro-max SKILL 자동 호출 + `python scripts/search.py "<query>" --refs` 조회 제안
- WHEN: Figma Community Wanted 파일 참조 필요
  THEN: `references/wanted-design-system/FIGMA.md` 읽고 `mcp__plugin_design_figma__*` 호출
- NEVER: Toss 코드를 프로젝트로 복사 (참조만 — `_large_data/toss-apps-in-toss/` 라이선스 불명확)
- ALWAYS: Montage 코드 재사용 시 MIT 주석 포함 (`references/wanted-design-system/ATTRIBUTION.md` 참조)

---

## §v3 검증 자동 트리거 (2605010914)

> **사용자 핵심 제약**: backtest_engine.py 자동 게이트 제외 — 차트 튜닝 흐름 보호.

### A. 코드 작성 흐름
- WHEN 새 모듈 디렉토리 생성 (mkdir + 파일 0~1개)
  THEN test-process 권고만 (자동 호출 X — 사용자 결정)
- WHEN testplan.json 존재 + 코드 추가
  THEN /verify Step 1.7가 testplan 우선 적용

### B. Validation 자동 트리거
- WHEN /verify Verification PASS 후
  THEN vv-separator 자동 호출 (Validation)
- **단, 변경 파일이 backtest_engine.py 단독이면 자동 호출 SKIP** (사용자 결정)
- WHEN vv-separator MISALIGNED
  THEN 즉시 FAIL → 수정 루프

### C. 커버리지/Mutation
- WHEN backend Python 변경 + 분기 커버리지 < 80%
  THEN coverage-gate.sh 훅이 additionalContext 알림
- **WHEN backtest_engine.py 변경**
  **THEN coverage-gate.sh silent skip** (`COVERAGE_GATE_SKIP_PATTERN=backtest_engine\.py$`)
- WHEN risk_gate / kill_switch / convex_sizer 변경
  THEN coverage-gate 95% 강제 + mutation-test L5 컨센트 + trading-safety-tester 호출

### D. 자연어 산출물
- WHEN 보고서/매뉴얼/품의서/공지 생성 직후
  THEN multi-judge 자동 호출 (J1+J3 기본)
- WHEN 사용자 발화 "엄격히/정확히/리뷰"
  THEN multi-judge에 J2(/codex:review) 추가

### E. LLM 회귀
- WHEN ~/.claude/skills/*/SKILL.md 변경
  THEN llm-eval-suite 자동 실행 (LLM_EVAL_AUTO_CI=1)
- 일일 5 USD cap (CLAUDE_VERIFY_DAILY_BUDGET_USD) 초과 시 skip
- WHEN ~/.claude/rules/*.md 변경
  THEN 영향받는 스킬 모두 eval

### F. Trajectory
- ALWAYS PostToolUse / Stop
  THEN trajectory-recorder 기록 (async, silent)
- 사용자 결정: PreToolUse / UserPromptSubmit는 등록 X (daily-fit이 이미 커버)

### G. Stop verifier (env 토글)
- WHEN CLAUDE_STOP_VERIFIER_ENABLED=1 + Stop + Edit/Write 발생
  THEN stop-verifier-subagent 호출 (haiku fresh)
- 기본 비활성 (사용자 결정)

### H. 우선순위 충돌
- WHEN /verify와 verification-pipeline 동시 매칭
  THEN /verify 우선 (코드 수정 직후 경량)
- WHEN /verify와 vv-separator 동시 매칭
  THEN /verify 먼저 → 그 후 vv-separator (V→V&V 순서)
- WHEN 모든 검증 스킬 종료
  THEN deb-bundler 자동 호출 (보고 표준화)

---

## §v4 코딩·의사결정·자가발전 자동 트리거 (2605011041)

> v4 R1 준수: 트레이딩 진입 결정에 자동 트리거 없음.
> v4 R3 완화: Cynefin/devils-advocate/prompt-refiner UserPromptSubmit 10% 샘플링.

### A. 코딩 자동 트리거

- WHEN 새 기능 구현 요청 (3개+ 파일 예상) AND NOT backtest_engine.py
  THEN plan-mode-router 자동 발동 (Opus Plan → Sonnet Impl)
- WHEN 구현 완료 선언 직전
  THEN spec-driven-coder 계약 준수 확인 (docstring + TC 존재 여부)
- WHEN SKILL.md `model:` frontmatter 누락 감지 (anti-pattern-blocker)
  THEN additionalContext 경고 + skills-v2-migrator 권고
- WHEN Edit/Write + plan.md 범위 외 파일
  THEN surprise-detector 경고 (블로킹 아님)

### B. 의사결정 자동 트리거 (10% 샘플링 — R3)

- WHEN UserPromptSubmit + Cynefin 키워드 감지 (cynefin-router.sh)
  THEN 도메인 분류 힌트 additionalContext (SIMPLE/COMPLICATED/COMPLEX/CHAOTIC)
  **단, 10% 확률 샘플링 (R3 완화)**
- WHEN UserPromptSubmit + 결정 키워드 감지 (devils-advocate-trigger.sh)
  THEN 반론 권고 additionalContext (/devils-advocate)
  **단, 10% 확률 샘플링 + R1 트레이딩 진입 키워드 시 SKIP**
- WHEN A 위험도 자산 변경 (risk_gate/kill_switch/convex_sizer)
  THEN pre-mortem 자동 발동 (위험 ≥3 강제)
- WHEN SDG 6요소 중 약한 고리 2개+
  THEN decision-helper 강화 제안

### C. 자가발전 자동 트리거

- WHEN Stop + 코드 변경 감지
  THEN dora-metrics-collector 기록 (async, silent)
- WHEN PostToolUse Skill 도구 호출
  THEN use-counter.sh 기록 (async, silent)
- WHEN 자산 총수 ≥ ASSET_BLOAT_WARN_THRESHOLD (180)
  THEN asset-archiver 경고 + obs JSONL 이벤트
- WHEN 자산 총수 ≥ ASSET_BLOAT_CRITICAL_THRESHOLD (200)
  THEN harsh-critic-stop이 🚨 CRITICAL 알림
- WHEN AUTO_MUTATION_ENABLED=1 + daily-fit-engine DNA 후보 생성
  THEN auto-mutation-pipeline staging area 경유 제안 (사용자 OK 필요)

### D. 분기 회고 자동 트리거

- WHEN 분기 경과 (3개월) + 사용자 명시 호출
  THEN double-loop-quarterly 발동 (사용자가 governing variable 선택)
  **자동 트리거 없음 — 사용자 결정 (R8 준수)**

### E. 백테스트 보호 (§v3 + §v4 통합)

- WHEN backtest_engine.py 수정
  THEN coverage-gate.sh SKIP + vv-separator SKIP + plan-mode-router SKIP
  (차트 튜닝 흐름 완전 보호)
