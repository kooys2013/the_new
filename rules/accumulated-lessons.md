---
paths:
  - "**/*"
---
# 누적 교훈

## ALWAYS
- Write tool 전 반드시 Read 먼저 [SCP-5] [since:26/03/15] [reinforced:26/04/11]
- lucide-react-native 아이콘 존재 확인 후 사용 [SCP-3] [since:26/03/20]
- [RN] expo-file-system → expo-file-system/legacy 에서 import [SCP-1] [since:26/03/22]
- [RN] router.replace(root) 실패 시 Platform.OS===web 분기 [SCP-3] [since:26/03/25]
- [GO] rules 파일 `paths:` frontmatter 검증 (`scope:` 잘못된 키) [SCP-1] [since:26/04/05]
- [GO] 장시간 세션 전 /save 체크포인트 [SCP-2] [since:26/04/08]
- [GO] ALWAYS: 전략 카드 작업 시작 전 dory-knowledge search_principle 1회 호출 [SCP-5] [since:26/04/13]
- [KNOW] ALWAYS: Edit/Write 전 Read 후 파일 해시 검증 (edit-integrity-guard 훅이 자동 강제) [since:26/04/18]
- [KNOW] wing_knowledge drawer는 Compiled Truth + Timeline 포맷 준수 [since:26/04/18]
- [KNOW] 상단 재작성 시 last_compiled 갱신, 하단은 append-only 유지 [since:26/04/18]
- [KNOW] 기존 지식 대체 시 supersedes 필드로 체인 추적 [since:26/04/18]
- [GO][PINE] ALWAYS: Pine PDCA 자동 Edit 예외 — `pine-expert` 에이전트는 `go-v2/pine/**/*.txt` scope에서만 `claude -p --permission-mode acceptEdits` 재귀 호출 허용. 파일명 타임스탬프 정책 + MAX_ITER 3 + timeout 900s 4중 방어 전제. [since:26/04/21]
- [HARNESS] ALWAYS: rules 신규 작성 시 paths 기본값 = `__on_demand_only__` 강제. `**/*` 광범위 패턴은 Core DNA 6종만 허용. 신규 작성 후 `grep -c 'paths:.*\*\*/\*"' ~/.claude/rules/*.md` 로 7개 초과 여부 확인 [SCP-2 컨텍스트열화] [since:26/04/28]
- [GO][SAFETY] ALWAYS: 화이트리스트 regex 검증은 `re.fullmatch(...)` 사용. `re.match(r"^...$")`는 trailing `\n` 통과 (`$`는 줄끝 매칭, `\n` 허용) → SQL/URL 인젝션 트랩. 대안: `re.fullmatch(...)` 또는 `re.match(r"^...\Z")` [SCP-3 복잡도회피] [since:26/04/30]
- [GO][SAFETY] ALWAYS: 자금 직결 엔드포인트(killswitch, cancel_all, mode_switch, regime_gate, risk_gate)는 단계별 ok 플래그를 응답 본문에 노출 + 자금-결정 단계 1개라도 실패 시 `status_code=500`. `ok=true` 단일 플래그 금지 — `cancel_ok`/`mode_switch_ok`/`alert_ok` 분리 후 `fund_critical_ok = cancel_ok and mode_switch_ok` 로 게이트 [SCP-5 검증연극] [since:26/04/30]
- [GO][SAFETY] ALWAYS: regime / risk / 안전 게이트 예외 시 **fail-closed** (continue/skip entry) — 자금 보호 게이트는 silent fail이면 진입 허용으로 변질. `_regime_state` 같은 게이트 변수가 try 블록 안에서만 정의되면 except 경로에서 NameError → 다음 봉 자동 진입 [SCP-1 조기종료] [since:26/04/30]
- [GO][LOG] ALWAYS: try/except 로깅 레벨 분류 — `logger.exception(...)` = 자금 직결 + stack trace 필수, `logger.warning(..., exc_info=True)` = 운영 영향 있으나 자금 흐름 외, `logger.debug(..., exc_info=True)` = 종료 경로/설정 누락/예상된 예외. silent `pass`는 셋 다 아님 = 금지 [SCP-5 검증연극] [since:26/04/30]

## NEVER
- NEVER: `sleep N && command` 패턴 Bash 사용 — 차단됨. 백그라운드 잡 대기는 ScheduleWakeup 또는 Monitor until-loop 사용 [since:26/04/18]
- [GO][CHART] NEVER: 소비자 없는 배열을 MgtgResult에 추가 — 추가 전 반드시 `grep -r 'fieldName' src/` 확인. 소비자 0 = 즉시 제거 대상 [since:26/04/25]
- [GO][CHART] NEVER: step-function 값(수십봉에 한 번 바뀜)을 Float64Array(n)으로 저장 — compact event array `[bar,val,bar,val,...]` 사용 [since:26/04/25]
- [GO][CHART] NEVER: `arr[i]` 단일 접근 패턴 배열을 MgtgResult로 출력 — 스칼라 inline으로 대체 (Float64Array(n) 제거) [since:26/04/25]
- [GO][VITE] NEVER: dev-only CSS를 `import "./styles.css"` 정적 import로 로드 — production 빌드 시 Vite가 JS 모듈 alias와 무관하게 CSS를 번들에 포함. 반드시 JS에서 동적 `<style>` 삽입으로 대체 [since:26/04/25]
- [GO][VITE] NEVER: dev-only 설명 문자열(ShortcutOverlay DEBUG_TOOLS, manual page dev section)을 production 컴포넌트에 조건 없이 넣기 — `import.meta.env.DEV` 가드로 tree-shake 필수 [since:26/04/25]
- LangChain JsonOutputParser 반환값에 .get() 금지 (Pydantic 인스턴스) [SCP-1] [since:26/03/10] [reinforced:26/04/05]
- 전역 vector_store 싱글턴 재도입 금지 [SCP-3] [since:26/03/18]
- [GO] rules/hooks 생성 후 settings.json 참조 미확인 [SCP-1] [since:26/04/06]
- [GO][BT] 백테 도메인 교훈 → `go-v2/.claude/rules/backtest-lessons.md` (26/04/17 승격)
- [KNOW] NEVER: edit-integrity-guard "외부 변경됨" 경고 무시하고 Edit 강행 (병렬 워크트리 race 유발) [since:26/04/18]
- [KNOW] wing_knowledge에 대화 로그·실수 기록·추측 금지 [since:26/04/18]
- [KNOW] Compiled Truth 섹션 append 금지 — 재작성만 허용 [since:26/04/18]
- [KNOW] Timeline 과거 항목 수정·삭제 금지 [since:26/04/18]
- [KNOW] NEVER: Codex `task --write` / `rescue` 명령을 훅에서 자동 호출 — 쓰기 가능 = 리스크. 리뷰 명령(review/adversarial-review)만 auto. 쓰기는 항상 사용자 명시 승인 [since:26/04/18]
- [GO][SAFETY] NEVER: hot path / 자금 직결 코드에서 `except Exception: pass` (또는 `continue`/`return`/`...` 단독). 반드시 `logger.exception` / `logger.warning(exc_info=True)` / `logger.debug(exc_info=True)` 중 영향도에 맞는 레벨 선택 + 컨텍스트 변수(symbol/direction/event_type) 포함. 검증 연극(SCP-5) 1순위 패턴 [SCP-5 검증연극] [since:26/04/30]
- [GO][SAFETY] NEVER: `re.match(r"^[A-Z0-9]+$", value)` 같은 ^...$ regex로 사용자 입력/심볼 검증 — `$`는 trailing `\n`을 허용 (Python `re.MULTILINE` 무관). SQL/URL/path 인젝션 통로. `re.fullmatch` 또는 `\Z` 강제 [SCP-3 복잡도회피] [since:26/04/30]
- [GO][SAFETY] NEVER: 안전 엔드포인트(killswitch, /bot/kill-switch, /live/killswitch)에 try/except 없는 native call (`await order_manager.cancel_all()`, `mode_router.set_mode("paper")`) — 1단계 실패 = 전체 500, 다음 단계 영구 미실행. 단계별 try/except + ok 플래그 mandatory [SCP-1 조기종료 + SCP-5 검증연극] [since:26/04/30]

## WHEN...THEN
- WHEN 같은 에러 2회 THEN unbounded 재검토 [since:26/03/15] [reinforced:26/04/08]
- WHEN PR 전 THEN /review + /cso 필수 [since:26/03/15] [reinforced:26/04/10]
- WHEN UI 신규 구현 THEN ui-ux-pro-max --design-system 먼저 [since:26/03/28]
- WHEN 프론트엔드 변경 완료 THEN /visual-proof 실행 [since:26/03/28]
- WHEN CLAUDE.md 50줄 초과 THEN rules/ 승격 검토 [since:26/04/01]
- WHEN 하네스 변경 THEN 훅·rules·스킬 정합 감사 [since:26/04/05] [reinforced:26/04/11]
- WHEN 근본원인 미특정 THEN 수정 진행 금지 — problem-solver Phase 2-A 4단계 프로토콜 우선 [SCP-5] [since:26/04/17]
- WHEN 완료 주장 THEN 5단계 검증 프로토콜(Identify→Execute→Read→Verify→Only Then) 필수 [SCP-5] [since:26/04/17]
- WHEN [KNOW] 3건 이상 타임라인 항목이 Compiled Truth와 모순 THEN 즉시 재작성 [since:26/04/18]
- WHEN [KNOW] 새 증거가 기존 지식 뒤엎음 THEN 신규 drawer + supersedes 연결 (기존 drawer 유지) [since:26/04/18]
- WHEN [KNOW] last_compiled 90일+ 미갱신 THEN stale-detector가 주간 리포트 생성 [since:26/04/18]
- WHEN [KNOW] 훅이 "외부 변경됨" 반환 THEN 재Read 실행 후 Edit 재시도 [since:26/04/18]
- WHEN 병렬 에이전트 분할 THEN fresh context per task + spec/quality 2단계 리뷰 [SCP-3] [since:26/04/17]
- WHEN SessionStart briefing에 `[CODEX-AUTO] ✅` 표시 THEN Claude `/review` 재실행 금지 — GPT 독립 리뷰가 이미 완료됨, 동일 diff 재리뷰는 토큰 낭비 + 품질 이득 0. `/codex:result <job-id>`로 결과만 확인하고 판단 진행 [since:26/04/18]
- WHEN `[CODEX-AUTO] ⏳ 진행중` THEN Codex 완료 대기, /review 중복 금지 [since:26/04/18]
- WHEN `[CODEX-AUTO] ❌ 실패` THEN 실패 근거(쿼터/네트워크/binary) 분석 후 수동 /codex:review 재시도 [since:26/04/18]
- WHEN [GO][SAFETY] except 블록 작성 THEN 영향도 분류 후 logger 레벨 선택: 자금직결→`logger.exception`, 운영영향→`logger.warning(exc_info=True)`, 종료/누락설정→`logger.debug(exc_info=True)`. silent `pass` 금지 + 컨텍스트 변수(symbol/direction/event_type) 메시지 포함 [since:26/04/30]
- WHEN [GO][SAFETY] 화이트리스트 regex 추가/수정 THEN `re.match` 발견 시 `re.fullmatch`로 즉시 교체 + 동일 모듈 내 grep으로 회귀 점검: `grep -nE 're\.match\(r"\^.*\$"' file.py` 결과 0건 확인 [since:26/04/30]
- WHEN [GO][SAFETY] 새 안전 엔드포인트(killswitch/cancel/mode_switch) 작성 THEN `live.py:209-259` (kill_switch 패턴)을 템플릿으로 복제 — 단계별 ok 플래그 + errors dict + status_code 분기 + JSONResponse [since:26/04/30]
- WHEN [GO][SAFETY] regime/risk gate 코드 수정 THEN gate 변수가 try 블록 밖(또는 except 경로)에서도 정의되어 있는지 확인 → NameError 패턴: `try: x = call()` + `if x:` 다음 줄 사용 = except 경로에서 `if x:`가 NameError. 해결: `except: continue` (fail-closed) [근거: backtest_engine.py:1846 latent NameError] [since:26/04/30]
<!-- origin: obra/superpowers@verification+debugging+subagent | merged: 26/04/17 -->
<!-- origin: GO v2 latent-bug sweep Tier 1 (16 hunks / 10 files) | merged: 26/04/30 -->

## [TRACE-LESSON] 추적성 교훈 카테고리
<!-- 3축 관찰 시스템 v2.7 추가 — 26/04/18 -->
- [TRACE-LESSON] 템플릿: WHEN {추적성 실패 상황} THEN {추적성 회복 액션} [since:YY/MM/DD]

## [DRIFT-LESSON] Drift 교훈 카테고리
- [DRIFT-LESSON] 템플릿: WHEN {drift 감지 상황} THEN {baseline 갱신 or rollback} [since:YY/MM/DD]

## [UX-LESSON] UX 리허설 교훈 카테고리
- [UX-LESSON] 템플릿: WHEN {생성물 유형 + 점수} THEN {페르소나별 개선 패턴} [since:YY/MM/DD]

## 메타데이터 규칙
- [SCP-N]: 해당 교훈이 방어하는 실패 유형
- [since:YY/MM/DD]: 최초 기록일
- [reinforced:YY/MM/DD]: 마지막 참조/강화 날짜
- 90일간 reinforced 없으면 [STALE] 태그 자동 부여 (auto-triggers.md 연동)
