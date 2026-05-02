---
description: Anthropic + Claude Code 2026년 5월 핵심 신패턴 단일 출처 — 다른 rules에서 링크만
paths:
  - "__on_demand_only__"
---

# Anthropic / Claude Code — 2026년 5월 핵심 요약

> 이 파일이 단일 출처. 다른 rules/skills에서는 이 파일을 링크만 할 것.
> apr2026.md의 후속편 — apr 본문은 그대로 유지, 5월 이후 신글만 수록.
> 반영 완료 파일: `rules/multi-agent-patterns.md`, `skills/verify/SKILL.md`, `rules/skill-quickref.md`, `~/.claude/projects/.../memory/feedback_iter_metric_industry_validated.md`

---

## 1. Anthropic Code Review (멀티 AI 리뷰어, agent-based)
**핵심**: 단일 외부 리뷰어를 넘어 **agent-based 멀티 리뷰어** 동시 실행.
- 1000+ LOC PR에서 **84% findings 정확도** 보고
- 패턴: orchestrator가 N개 reviewer agent를 fan-out → 결과 합류 → 사람 결정
- Review 패턴(`rules/multi-agent-patterns.md §4`)의 "멀티 리뷰어 변형"
- **반영**: `rules/multi-agent-patterns.md` §4 표 안 변형 행 추가

## 2. Self-Verification 3-Layer
**핵심**: 검증을 **종류별 직교 분해** — Syntax / Intent / Regression
- Syntax: 컴파일·타입·lint (도구 출력)
- Intent: 변경이 *의도*한 동작을 만드는가 (사람·모델 판단)
- Regression: 기존 동작 보존 (테스트 스위트)
- 우리 `/verify` L0~L5는 **자원 분류** — 3-Layer는 **검증 종류** — 직교 통합
- **반영**: `skills/verify/SKILL.md` Step 2 다음에 라벨링 섹션 추가, 결과 보고에 어떤 Layer 검증했나 1단어 명시 의무화

## 3. Computer Use (macOS UI 자동화)
**핵심**: macOS 한정 UI 자동화. AppleScript 대안.
- **거부 결정**: 우리는 Windows + `/browse` (Playwright) + `connect-chrome` (handoff) 조합으로 동등 이상
- **반영 없음** (의도적 비채택)

## 4. Auto Mode (permission classifier)
**핵심**: 작업 위험도 자동 분류 → 안전 작업 무중단 / 위험 작업 컨센트
- 우리 `settings.json`: `defaultMode: "auto"` + `skipDangerousModePermissionPrompt: true` 이미 활성
- **반영 없음** (이미 동등 운영)

## 5. Channels + Dispatch
**핵심**:
- Channels: Discord/Telegram/iMessage 외부 IM 통합 — 세션 외부 푸시
- Dispatch: 모바일에서 비동기 작업 트리거
- 우리 `settings.json`: `channels: ["plugin:telegram@..."]` + `agentPushNotifEnabled` + `enableRemoteControl` + `remoteControlAtStartup` 이미 활성
- **반영 없음** (이미 동등 운영)

## 6. Context Engineering 3-Techniques
**핵심**: 장기 horizon 에이전트 컨텍스트 관리 3종
1. **Compaction** — 세션 자동 압축 (우리 PreCompact mempal hook ✅)
2. **Structured note-taking** — 중간 산출물을 외부 파일에 구조화 (우리 `_cache/obs/*.jsonl` 부분 동등)
3. **Multi-agent architectures** — 컨텍스트 분리 (우리 Agent tool ✅)
- **갭**: structured note **재조회** 경로 부재 → P1 큐잉 (`obs-recall.sh` 별도 세션)
- **반영**: P1 mutation-260501.json

## 7. Skills v2 Frontmatter
**핵심**: 스킬 frontmatter 신 필드
- `effort: high|medium|low` — 모델 효력 오버라이드 (사용량 ORANGE/RED 시 자동 강등 가능)
- **embedded hooks** — `onPreToolUse / onComplete` 등을 skill YAML에 직접 — component lifecycle scope (글로벌 hook 노이즈 ↓)
- `auto-invoke` 제어 — Claude 자동 호출 여부 결정
- `subagent` 실행 옵션
- **반영**: P1 큐잉 (unbounded-engine, problem-solver, cso 등 opus 강제 스킬에 effort 명시 — 별도 세션)

## 8. /loop Interval Slash Command
**핵심**: `/loop 5m /your-command` — 슬래시 명령을 인터벌로 자율 반복
- 우리 `ralph-strategy` + `pdca-iterator` 가 더 풍부 (기록·상한·평가)
- /loop은 **라이트 사용처**에 적합 (단순 모니터링·짧은 폴링)
- **반영**: `rules/skill-quickref.md` 도구 표에 1행 추가

## 9. Plugin Hook YAML Frontmatter Bug Fix
**핵심**: 4월 changelog — plugin skill hooks가 silent 실패 / `CLAUDE_PLUGIN_ROOT` 미설정 시 "No such file or directory"
- 우리 활성 플러그인 5종 (bkit / ralph / vibe-sunsang / codex / usage-gate) — 현재 silent fail 보고 없음
- **반영 없음** (모니터링 유지)

## 10. Subagent Best Practices (clean handoff + continuity)
**핵심**: 서브에이전트 호출 시 두 모드 명확 구분
- **fresh** — 빈 컨텍스트로 새 에이전트 (Agent tool 기본)
- **continuity** — 이전 에이전트 ID로 SendMessage 재진입 (메모리 유지)
- prompt는 **self-contained** (대화 히스토리 의존 금지)
- 결과 검증: "*의도*한 것" ≠ "*실제 한* 것" — diff 확인 필수
- **반영**: `rules/multi-agent-patterns.md` §1 Orchestrator 섹션에 양식 1줄 추가 (P1)

---

## 6월 이후 재동기화

- `hooks/weekly-fit-analyzer.sh` 일요일 22:00 주간 블로그 스캔
- `skills/unbounded-engine` Phase 2 가 최근 30일 글 1개+ 참조 의무
- 새 핵심 글 등장 시 이 파일 §11~ 추가 + 반영 파일 목록 갱신
- 분기 1회 (3/6/9/12월) `apr2026.md` `may2026.md` ... 합본 `2026-q2.md` 검토

---

## 출처

- [Extend Claude with skills — Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Claude Code Changelog 2026](https://claudefa.st/blog/guide/changelog)
- [claude-code/CHANGELOG.md (anthropics/claude-code)](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- (Anthropic 공식 블로그 4-5월 다수 — 본 파일 §1~§10 각각의 출처 분산)
