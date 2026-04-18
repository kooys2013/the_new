<!-- last-updated: 26/04/17 -->
---
description: 54+ 스킬 1페이지 퀵레퍼런스 — 키워드→스킬 매핑으로 ORCH 축 강화
paths:
  - "**/*"
---

# Skill Quick Reference

> 54+ 스킬은 description 키워드로 자동 트리거. 어떤 키워드가 어떤 스킬을 부르는지 1분 안에 찾기.

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
| verification-pipeline | 배포 전 검증, Go/No-Go, 한방에 검증 | 전체 검증 파이프라인 |
| cso | 보안, 취약점, RLS, 인증 | 보안 감사 (opus) |
| review / codex:rescue | 리뷰, PR 전 검토 | /review + /codex 교차검증 |

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
| gstack | g-stack 프로젝트 | g-stack 전용 |
| bkit:* | b-kit, PDCA, 엔터프라이즈 | b-kit 전용 |
| less-permission-prompts | 승인 프롬프트 줄이기 | allowlist 자동 생성 |

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
