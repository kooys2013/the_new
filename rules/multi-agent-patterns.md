<!-- last-updated: 26/04/17 -->
---
description: 다중 에이전트 조율 6 패턴 — Orchestrator/Swarm/Pipeline/Review/Fan-out/Debate
paths:
  - "**/*"
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

**하네스 매핑**: harsh-critic, `/codex:adversarial-review`, bkit:design-validator, bkit:gap-detector.

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

## 패턴 선택 플로우

```
작업 시작 →
├── 정답 없는 결정 + 편향 우려? → YES → Debate
├── 서브작업 서로 영향? → YES → Swarm
├── 단계별 변환? → YES → Pipeline
├── 품질 게이트 필수? → YES → Review
├── 독립 N개? → YES → Fan-out
└── 중앙 분할 가능? → YES → Orchestrator
```

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
