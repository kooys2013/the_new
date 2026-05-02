<!-- last-updated: 26/04/17 -->
---
paths:
  - "__on_demand_only__"
---
# 모델 전략 규칙 (v2.6)

> 3가지 입력으로 모델을 결정한다:
> ① 작업 특성 (사고 vs 실행) ② 잔여 사용량 (usage-gate) ③ 교훈 (과거 성과)

## 1. 기본 모델 선택

| 작업 특성 | 모델 | 이유 |
|----------|------|------|
| 전략 판단 / 아키텍처 결정 | opus | 멀티스텝 추론 필수 |
| 근본 원인 분석 (5Whys) | opus | 인과 추론 깊이 |
| 보안 감사 / 취약점 분석 | opus | 미묘한 패턴 탐지 |
| 연구 합성 / 교차 분석 | opus | 복수 소스 통합 |
| 코드 구현 / 기능 개발 | sonnet | 충분한 코딩 역량 |
| 반복 루프 (ralph-loop) | sonnet→haiku | 수십 회 호출 → 비용 |
| QA 자동화 / 브라우저 | sonnet | 실행 중심 |
| 배포 / git / PR 워크플로 | sonnet | 절차적 |
| 상태 토글 / 단순 체크 | haiku | 로직 없는 I/O |
| **traceability-weaver** (Phase 1-3) | sonnet | Grep + 매트릭스 갱신 |
| **ux-rehearsal** (채점) | sonnet | roleplay 채점 (haiku 불가) |
| **drift-sentinel** (심각도 판정) | sonnet→haiku 위임 | 분기 로직 단순 |
| **observability-bus** (집계) | haiku | 파일 IO + 카운트만 |

> 참고 휴리스틱: `Haiku=분류/라벨링, Sonnet=구현 기본, Opus=아키텍처/3회 실패 에스컬레이션` — 토큰 30~50% 절약 보고.
> <!-- origin: Yeachan-Heo/oh-my-claudecode@smart-routing | merged: 26/04/17 -->

> **Opus 4.7 강점 (2026/04 업데이트)**: 확장된 추론 깊이(아키텍처·보안·연구 합성 특화), 도구 호출 정확도 개선, 장문 컨텍스트(200k) 전체 활용 능력 향상.
> <!-- origin: claude.com/blog/opus-4-7 | merged: 26/04/17 -->

## 2. 사용량 기반 작업 권장 안내

> 강제 아님 — 사용량 구간에 따라 작업 페이스 권장만 한다.
> 사용량 확인: Claude.ai 대시보드 또는 상태표시줄(usage-gate 설치 시)

| 구간 | 상태 | 모델 권장 | 작업 권장 안내 |
|------|------|----------|--------------|
| 0~60% | GREEN | 자유 | 자유롭게 진행 |
| 60~80% | YELLOW | 사고만 opus | "대형 신규 작업은 내일 시작 권장" |
| 80~90% | ORANGE | opus 자제 | "마무리·소형 작업만 권장. 대형 작업은 보류" |
| 90%+ | RED | opus 금지 | "오늘 작업 중단 권장. 내일 재개하세요" |

### 안내 타이밍

- 작업 시작 시 사용량이 YELLOW 이상이면 → 위 안내를 먼저 제시
- 작업 도중 RED 진입이 예상되면 → "여기서 멈추고 내일 이어가는 걸 권장합니다" 제안
- 안내 후 사용자가 계속 진행 원하면 → 그대로 진행 (강제 아님)

### 모드별 권장 임계값 참고

| 모드 | 주의 시작 | 이유 |
|------|---------|------|
| 무한조언 | 90% | opus 소비 적음 |
| 한방에 개발 | 60% | 대규모 반복 → 여유 필요 |
| 한방에 검증 | 80% | 보안 축만 opus |
| 무한실행 | 60% | 장시간 자율 실행 |
| ralph-loop | 50% | 수십 회 반복 → 최대 절약 |

## 3. 모델 전환 규칙

| 방향 | 방법 | 사용자 확인 |
|------|------|------------|
| 업그레이드 (sonnet→opus, 대화형) | AskUserQuestion 먼저 | **필수** |
| 업그레이드 (서브에이전트 Opus 위임) | Agent(model="opus") | **필수** |
| 다운그레이드 (opus→sonnet) | 자동 복귀 | 생략 |
| 서브에이전트 Haiku 위임 (반복 루프) | Agent(model="haiku") 자동 | 생략 |

**업그레이드 확인 메시지 형식:**
```
이 작업은 Opus가 적합합니다.
이유: [전략 판단 / 보안 감사 / 근본 원인 분석 / 연구 합성]
→ Opus로 전환할까요?
  Y: 서브에이전트 Opus 위임 또는 /model claude-opus-4-6 실행 안내
  N: Sonnet 유지
```

**다운그레이드는 자동 (안내만):**
```
작업 완료 — Sonnet으로 복귀합니다. (별도 확인 없음)
```

## 4. 교차검증 에스컬레이션

문제가 해결되지 않으면 같은 모델로 더 시도하지 말고 다른 모델로 교차 검증.

| 시도 | 현재 모델 | 결과 | 다음 행동 |
|------|---------|------|----------|
| 1차 | 기본 모델 (예: sonnet) | 실패 | 재시도 (다른 접근) |
| 2차 | 기본 모델 | 재실패 | ⚠ 모델 변경 권장 (사용자 확인) |
| 3차 | **opus로 승격** | 성공 → 교훈: "이 유형은 opus 필요" |
| 3차 | opus 승격 | 재실패 | /codex (교차검증) |
| 4차 | **codex 교차** | 성공 → 교훈: "Claude 편향 — codex가 맞음" |
| 4차 | codex도 실패 | — | unbounded-engine 재진입 (문제 재정의) |

## 4.5 Advisor 패턴 (Sonnet + Opus 단일 턴)

> "opus 전면 전환이 과한데 판단 지점만 Opus가 필요" → **3.5차 시도**로 Advisor 우선.
> 상세 스펙: `rules/advisor-strategy.md`
> <!-- origin: claude.com/blog/the-advisor-strategy | merged: 26/04/17 -->

에스컬레이션 사다리 내 위치:
```
1차 sonnet 실패 → 2차 sonnet 재시도 실패
  → [3.5차] Advisor (sonnet executor + opus advisor, max_uses=3)
    → [3차] opus 전면 전환 → [4차] /codex → unbounded-engine
```

| 사용 | 판단 기준 |
|------|----------|
| ✅ 구현 + 아키텍처/보안 판단 동시 | Sonnet 실행, Opus가 판단만 |
| ✅ 대규모 리팩토링 | Sonnet 실행, Opus가 의존성 영향 추론 |
| ❌ 순수 코딩 / 순수 전략 / 반복 루프 | 단독 모델로 충분 |

사용량 가드: GREEN/YELLOW → Advisor OK | ORANGE → 자제 | RED → 금지

## 5. 교훈 기반 모델 승격/강등

### 승격 (sonnet → opus)
- "sonnet이 아키텍처 결정을 잘못함" → 전략 판단 opus 필수
- "보안 취약점을 sonnet이 놓침" → 보안 감사 opus 강제
- "같은 에러 2회 반복 (sonnet 세션)" → 해당 유형 opus 시도

### 강등 (opus → sonnet)
- "이 유형 작업에 opus 불필요했음" → 비용 절감
- "sonnet으로 충분히 해결됨" → 실측 근거
- "ralph-loop에서 opus가 반복 소비만 증가" → 반복 작업 haiku

### 교훈 형식 (CLAUDE.md에 축적)
```
WHEN: [작업 유형] THEN: model=[opus/sonnet/haiku]
  근거: [언제, 어떤 시도에서, 왜 이 결론]
```

## 6. Codex 적극 활용 가이드 (공식 플러그인)

> Codex 쿼터는 ChatGPT 구독에 포함 — 쓰지 않으면 낭비.
> 상태 확인: `/codex:setup` | 설정: `.codex/config.toml`

### 모드별 활용 우선순위

여유 시 아래 순서로 적극 활용:
1. `/codex:review` — 모든 PR 전 GPT 독립 리뷰 (가장 가치 높음) — **Stop hook이 자동 대기 마커 생성**
2. `/codex:adversarial-review` — 아키텍처/설계 결정 시 도전적 검증 (민감 파일 변경 시 자동 권고)
3. `/codex:rescue` — 교착 시 작업 위임 (선별 사용)

### model + effort 선택 전략 (쿼터 최적화)

| 상황 | 모델 | effort | 플래그 예시 |
|------|------|--------|------------|
| 루틴 리뷰 (Stop hook 자동) | `spark` | `low` | `--model spark --effort low --background` |
| PR 전 브랜치 전체 리뷰 | 기본(gpt-5.4) | `medium` | `--base main` |
| 아키텍처/보안 심층 검증 | 기본(gpt-5.4) | `high` | `--scope branch` |
| 교착 rescue (교착 해제 목적) | 기본 | `xhigh` | `--effort xhigh` |
| 이전 rescue 스레드 재개 | 기본 | `medium` | `--resume` |

> `spark` = `gpt-5.3-codex-spark` 별칭. 쿼터 소비 최소 → 루틴 리뷰에 적합.
> Plus 기준 5시간 창에서 GPT-5.4 약 40분 / spark 약 120분 사용 가능.

### 작업 흐름 내 Codex 삽입 지점

| 하네스 단계 | Codex 활용 | 자동화 수준 |
|------------|-----------|------------|
| 세션 종료 (코드 변경 시) | Stop hook → 마커 생성 → 다음 briefing 노출 | **자동** |
| 코드 구현 완료 | `/codex:review --model spark --effort low` | 반자동 (briefing 권고) |
| problem-solver 2회 실패 | `/codex:rescue --resume` (→ 없으면 fresh) | 반자동 (트리거 권고) |
| 민감 파일 변경 (auth/rls/sql) | `/codex:adversarial-review --scope working-tree` | 반자동 (briefing 권고) |
| 브랜치 머지 전 | `/codex:review --base main` | 수동 (/ship 직전) |
| 보안 /cso 후 | `/codex:adversarial-review --scope branch` | 수동 (RLS/인증 변경 시) |
| 스프린트 종료 | `/codex:review --base main` | 수동 (전체 diff) |

### 사용 빈도 권장

| 일간 사용 | 강도 | 권장 행동 |
|----------|------|----------|
| 0회 | LOW | **적극 활용** — briefing의 Codex 대기 항목 확인 |
| 1~4회 | MEDIUM | 적정 — 현재 페이스 유지 |
| 5~9회 | HIGH | 활발 — rescue 위주로 선별 사용 |
| 10회+ | MAX | 핵심만 (rescue/adversarial), spark 모델 우선 |

### Codex 결과 처리 규칙
- `/codex:rescue` 결과는 Claude가 diff 확인 + typecheck 후 적용
- Codex와 Claude 의견 상반 시 → 양측 근거 제시 (User Sovereignty)
- 리뷰 게이트(`--enable-review-gate`)는 유인 세션에서만, 30분 제한
- `/codex:status --all` — 세션 간 백그라운드 잡 확인 (다음 세션에서 결과 회수 가능)

## 6.5 Opus vs Codex 선택 기준

| 상황 | 선택 | 이유 |
|------|------|------|
| 내부 교차 검증 (같은 히스토리) | **Opus advisor** | 컨텍스트 공유, 단일 턴 효율 |
| 외부 시각 (독립 리뷰, 팀 편향 제거) | **Codex** | Claude 히스토리와 독립 |
| 보안 취약점 재감사 | Codex (`/codex:adversarial-review`) | 외부 시각이 더 신뢰 |
| sonnet 2회 실패 → 판단 지점만 필요 | **Advisor** (3.5차) | Opus 전면 전환 전 저비용 시도 |

<!-- origin: claude.com/blog (Apr 2026) | merged: 26/04/17 -->

## 7. 통합 흐름

```
작업 → [1] 교훈 확인 → [2] 잔여량 확인(Claude+Codex) → [3] 실행
  Claude 업그레이드 필요 → 사용자 확인 후 전환
  Claude 다운그레이드 → 자동 복귀 (안내만)
  Codex 여유 → 적극 활용 권장 (review/adversarial 제안)
  실패 → 교차검증 에스컬레이션 (sonnet→opus→/codex→unbounded)
  회고 시 모델 교훈 정리 → 다음 세션에서 모델 선택 최적화
```
