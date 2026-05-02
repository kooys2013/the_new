<!-- last-updated: 26/04/17 -->
---
description: 다중 에이전트 조율 6 패턴 — Orchestrator/Swarm/Pipeline/Review/Fan-out/Debate
paths:
  - "__on_demand_only__"
---

# Multi-agent Coordination Patterns

> Agent tool의 단순 위임을 넘어, 복잡 작업에 맞는 **조율 패턴 6종**.
> <!-- origin: claude.com/blog (Apr 2026 multi-agent coordination) + autopus-adk Debate (26/04/18) | merged: 26/04/17~18 -->

## 패턴 비교표

| 패턴 | 컨텍스트 공유 | 에이전트 간 통신 | 용도 | 기존 하네스 매핑 |
|------|--------------|-----------------|------|------------------|
| **Orchestrator** | 중앙 계획자만 전체 | 계획자→작업자 단방향 | 분할 가능한 복합 작업 | Task(Plan) + Task(Explore) 조합 |
| **Swarm** | 공유 스크래치패드 | 에이전트 간 자유 | 탐색형 문제 (최적화, 디자인) | ralph-strategy 자율 반복 |
| **Pipeline** | 순차 전달 | 출력→다음 입력 | 단계별 변환 (자료→분석→합성) | research-pipeline Phase 1→8 |
| **Review** | 실행자·검토자 분리 | 검토자→실행자 피드백 | 품질 게이트 필수 작업 | `/codex:review`, harsh-critic |
| **Fan-out** | 병렬 독립 | 무통신, 결과만 합류 | 독립 서브작업 다수 | 워크트리 병렬 + Agent 다중 호출 |
| **Debate** | 양측 입장 분리 + 익명 심판 | 라운드제 발언 → 맹인 채점 | 정답 없는 결정 (편향 우려) | Advisor 다턴 변형 + 무한조언 5인 자문위원회 |

## 1. Orchestrator (중앙 조율)

**언제**: 작업이 명확히 분할 가능하고, 분할 결과를 하나로 합쳐야 할 때.
**언제 피하나**: 각 서브작업이 서로 영향을 주는 경우 (Swarm이 나음).

```python
# 예시: "Auth 시스템 리뷰" → Orchestrator
Task(subagent_type="Plan", prompt="Auth 리뷰 마스터 플랜 수립")
  → 결과 기반으로 아래 3개 병렬 호출:
Task(subagent_type="Explore", prompt="JWT 구현 탐색")
Task(subagent_type="Explore", prompt="RLS 정책 탐색")
Task(subagent_type="Explore", prompt="세션 저장 탐색")
# 메인 스레드가 3 결과 통합 → 최종 리포트
```

**하네스 매핑**: planning-generator Phase 1 (PRD/FS/IA/UF) + bkit pdca의 CTO-Lead.

## 2. Swarm (탐색 병렬)

**언제**: 정답이 없고 여러 접근을 동시에 시도해야 할 때.
**언제 피하나**: 정답이 이미 알려진 단순 작업 (비용 낭비).

```python
# 예시: "성능 병목 찾기" → Swarm (같은 입력, 다른 관점)
Task(subagent_type="general-purpose", prompt="SQL 쿼리 관점 분석")
Task(subagent_type="general-purpose", prompt="네트워크 I/O 관점 분석")
Task(subagent_type="general-purpose", prompt="클라이언트 렌더링 관점 분석")
# 3 결과 중 가장 근거 있는 진단 채택
```

**하네스 매핑**: ralph-strategy (파라미터 탐색), unbounded-engine 다중 가설.

## 3. Pipeline (순차 변환)

**언제**: 각 단계 출력이 다음 단계 입력이 되는 선형 흐름.
**언제 피하나**: 단계 간 독립적인 경우 (Fan-out이 빠름).

```python
# 예시: research-pipeline Phase 1→8
Phase 1 (문제정의) → Phase 2 (소스수집) → ... → Phase 8 (합성)
# 각 phase 산출물을 다음 phase의 입력으로 명시 전달
```

**하네스 매핑**: research-pipeline, bkit PM→PLAN→DESIGN→DO→CHECK→REPORT.

## 4. Review (검토자-실행자)

**언제**: 품질 게이트가 필수이고, 독립 시각이 가치 있을 때.
**언제 피하나**: 실행자가 이미 충분히 검증된 경우.

```python
# 예시: PR 전 교차 검증
1. Sonnet 구현 완료
2. /codex:review (외부 시각)
3. Claude가 reviews 받아 반영 or 반박
# 양자 의견 상반 → user sovereignty
```

### 4-A. 멀티 리뷰어 변형 (Anthropic Code Review 패턴)

**언제**: 1000+ LOC PR / 보안 변경 / 아키텍처 결정 — 단일 외부 시각이 부족할 때.
**근거**: Anthropic Code Review (2026/05) — agent-based 멀티 리뷰어 동시 실행 시 1000+ LOC PR에서 **84% findings 정확도** 보고.

```python
# 예시: 대규모 PR → orchestrator + N 리뷰어 fan-out
1. Sonnet 구현 완료 (1000+ LOC)
2. Orchestrator가 3 reviewer agent 동시 호출 (관점 분리):
   - Task(subagent_type="general-purpose", prompt="아키텍처/설계 관점 리뷰")
   - Task(subagent_type="general-purpose", prompt="보안/취약 관점 리뷰")
   - /codex:review (외부 모델 관점)
3. 3 결과 합류 → 사람 결정 (user sovereignty)
```

**하네스 매핑**: 단일 `/codex:review` 사용처에서 **PR LOC > 1000** 또는 **민감 파일(auth/rls/sql) 변경** 시 이 변형으로 승격.

**Anthropic 신패턴 출처**: `rules/anthropic-blog-may2026.md §1`

**하네스 매핑(공통)**: harsh-critic, `/codex:adversarial-review`, bkit:design-validator, bkit:gap-detector.

## 5. Fan-out (독립 병렬)

**언제**: N개 독립 서브작업, 결과만 합쳐 반환.
**언제 피하나**: 서브작업이 공유 상태를 읽거나 써야 할 때.

```python
# 예시: "각 마이크로서비스의 README 요약"
Task(subagent_type="Explore", prompt="service-a README 요약")
Task(subagent_type="Explore", prompt="service-b README 요약")
Task(subagent_type="Explore", prompt="service-c README 요약")
# 3 결과를 표로 통합
```

**하네스 매핑**: 워크트리 병렬 (`isolation:"worktree"`), Agent tool 단일 메시지 다중 호출.

## 6. Debate (양측 대립 + 맹인 심판)

**언제**: 정답 없는 의사결정 (아키텍처/전략/모델 선택), 한쪽으로 치우치는 편향 우려.
**언제 피하나**: 명확한 정답이 있거나 한쪽이 압도적인 경우 (Review·Advisor가 더 효율).

```python
# 예시: "EKS vs ECS 선택" → Debate
# Round 1: 찬성 입장 / 반대 입장 발언 (1~2 라운드)
Task(subagent_type="general-purpose", prompt="EKS 채택 옹호 — 근거 3개 + 위험 1개 인정")
Task(subagent_type="general-purpose", prompt="ECS 채택 옹호 — 근거 3개 + 위험 1개 인정")
# 3번째 맹인 심판 (발언자 정체 모름):
Task(subagent_type="general-purpose", prompt="아래 두 입장 익명 채점: 근거 강도/위험 인지/실행 가능성. 발언자는 A/B로만 표기됨.")
# 결과 = 채점표 + 양측 핵심 논거
```

**Advisor와 차이**: Advisor는 **단일 턴 + executor 결정 권한**, Debate는 **다턴 + 익명 심판이 결정 제안**. 편향 제거가 핵심일 때 Debate.

**하네스 매핑**: Advisor + 무한조언 5인 자문위원회의 다턴·익명화 변형.

> <!-- origin: autopus-adk debate pattern | merged: 26/04/18 -->

## 패턴 선택 플로우 (간단 가이드)

```
작업 시작 →
├── 정답 없는 결정 + 편향 우려? → YES → Debate
├── 서브작업 서로 영향? → YES → Swarm
├── 단계별 변환? → YES → Pipeline
├── 품질 게이트 필수? → YES → Review
├── 독립 N개? → YES → Fan-out
└── 중앙 분할 가능? → YES → Orchestrator
```

## 결정 매트릭스 (v2.1 신규 — 결정론적 패턴 선택)

> v1 평가에서 지적된 "멀티에이전트 적용 매트릭스 부재" 갭 해결.
> *상황별로 어떤 패턴을 써야 하는지* 명시 — LLM 자율 판단 의존도 감소.

### 매트릭스 1: 작업 유형 × 패턴

| 작업 유형 | 1순위 패턴 | 2순위 (대안) | 비고 |
|----------|-----------|------------|------|
| 새 기능 구현 (3+ 파일) | **Orchestrator** (Plan + Explore N) | plan-mode-router (Opus Plan + Sonnet Impl) | backtest_engine.py SKIP |
| 디버깅 (2회 실패 후) | **Review** (/codex:rescue) | Advisor (3.5차) | 같은 모델로 재시도 금지 |
| 보안 감사 (RLS / 인증 / API) | **Review 4-A 멀티 리뷰어** | /codex:adversarial-review | 1000+ LOC PR 자동 승격 |
| 보고서·매뉴얼·자연어 산출물 | **Review** (multi-judge J1+J3) | Debate (편향 우려 시) | 사용자 발화 "엄격히" → +J2 |
| 트레이딩 전략 결정 | **Debate** (찬/반/심판) | Advisor | R1: 진입 신호는 도리님 원리만 |
| 기술 선택 (라이브러리 / 아키텍처) | **Advisor** (Sonnet+Opus) | Debate (이항 대립 시) | model-strategy 3.5차 위치 |
| 대규모 리팩토링 | **Orchestrator** (Plan + Fan-out) | Swarm (탐색 필요 시) | 파일 소유권 명시 |
| 성능 최적화 (병목 미상) | **Swarm** (관점 분리) | research-pipeline | SQL/IO/렌더링 병렬 가설 |
| 파라미터 탐색 / 자동 최적화 | **Swarm** (ralph-strategy) | Fan-out (독립 시드) | 5-cap 도달 시 Review로 전환 |
| 배포 전 검증 | **Pipeline** (verification-pipeline 9phase) | Review | Phase 11/12 (SDG/pre-mortem) |
| 회고 / 분기 검토 | **Pipeline** (retrospective-engine) | Debate (governing variable 검토) | R8: 사용자 선택 강제 |
| 독립 N개 데이터 수집 | **Fan-out** | Pipeline (순차 필요 시) | 워크트리 격리 |
| 단일 파일 1줄 수정 | **(패턴 없음)** | — | 직접 Edit, 멀티에이전트 비용 낭비 |

### 매트릭스 2: 위험도 × 패턴 강도

| 위험도 | 패턴 강제도 | 예시 |
|--------|-----------|------|
| **A (자금 직결)** | **Review 4-A 멀티 리뷰어 강제** | risk_gate.py / kill_switch.py / convex_sizer.py |
| **B (데이터 일관성)** | Review 권장 | DB 스키마 변경, API 계약 변경 |
| **C (일반)** | Advisor 또는 단일 모델 | UI / 일반 비즈니스 로직 |
| **D (탐색적)** | (패턴 없음) | backtest_engine.py 파라미터 튜닝 — R5 SKIP |

### 매트릭스 3: 컨텍스트 사용량 × 패턴 회피

| 사용량 | 회피 패턴 | 권장 대체 |
|--------|----------|----------|
| GREEN (0~60%) | 자유 | — |
| YELLOW (60~80%) | Swarm (N×전체 컨텍스트) | Fan-out (부분 컨텍스트) |
| ORANGE (80~90%) | Orchestrator + Swarm | 단일 Sonnet, Pipeline 단계별 출력 고정 |
| RED (90%+) | Advisor (Opus 토큰 소비) | Sonnet 단독, 컨센트 후 진행 |

### 매트릭스 4: 트레이딩 도메인 R1 격리

| 결정 유형 | 사용 가능 패턴 | 사용 금지 |
|----------|--------------|----------|
| **트레이딩 진입/청산 신호** | (없음 — 도리님 원리 KB만) | 모든 멀티에이전트 패턴 |
| 자금 게이트 코드 검증 | Review 4-A + trading-safety-tester | — |
| 백테스트 코드 변경 | (없음 — 사용자 직접 튜닝) | plan-mode-router, vv-separator 자동 |
| 백테스트 결과 해석 | Debate (찬/반/심판) | — |

## 자동 트리거 매핑 (skill-quickref.md 보강)

| 사용자 발화 키워드 | 자동 매칭 패턴 | 진입 스킬/명령 |
|------------------|--------------|--------------|
| "새 기능 만들어줘" / "처음부터 끝까지" | Orchestrator | /oneshot dev → plan-mode-router |
| "둘 중 뭐가 나아?" / "갈림길" | Debate | decision-helper → wrap-decision |
| "보안 감사" / "RLS 검토" | Review 4-A | /cso + /codex:adversarial-review |
| "PR 전 검토" / "리뷰" | Review | /review + /codex:review |
| "성능 병목" / "왜 느려" | Swarm | problem-solver → ralph-strategy |
| "파라미터 탐색" / "자동 최적화" | Swarm | ralph-strategy + ralph-loop |
| "배포 전 검증" / "한방에 검증" | Pipeline | /full-verify → verification-pipeline |
| "여러 페이지 비교" / "각 서비스 요약" | Fan-out | Agent N개 단일 메시지 호출 |
| "구현 + 보안 동시" | Advisor | model-strategy 3.5차 |

## 비용 관점

| 패턴 | 토큰 소비 | 병목 |
|------|----------|------|
| Orchestrator | 중앙 계획자 컨텍스트 누적 | 계획자 컨텍스트 한계 |
| Swarm | N 에이전트 × 전체 컨텍스트 | 공유 스크래치패드 동기화 |
| Pipeline | 단계별 컨텍스트 누적 | 최종 단계 컨텍스트 최대 |
| Review | 2~3배 토큰 | 검토자 반복 피드백 |
| Fan-out | N 에이전트 × 부분 컨텍스트 | 최소 (서브작업이 작을수록 효율) |
| Debate | 3에이전트 × 1~2라운드 (찬/반/심판) | 심판 익명성 보장 어려움 (프롬프트로 분리) |

## 위반 금지

- NEVER: Swarm을 대규모 파일 수정에 사용 (conflict 난장판)
- NEVER: Fan-out 에이전트가 같은 파일 쓰기 (race)
- NEVER: Review 없이 보안·인증 변경 완료 선언 (SCP-5)
- ALWAYS: Pipeline 각 단계 출력물을 명시 파일로 고정 (컨텍스트 의존 금지)

## 참조
- `rules/tool-routing.md` 병렬 개발 섹션
- `rules/advisor-strategy.md` (Advisor는 Review 패턴의 단일 턴 버전)
- `skills/research-pipeline/SKILL.md` (Pipeline 구체 구현)
