---
description: 코드 리뷰 통과 기준 5축 — 검·읽·일·안·추 (TRUST 5 한국어 매핑) — autopus-adk 차용
paths:
  - "**/*.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# 코드 리뷰 5축 (검·읽·일·안·추)

> `service-completion-checklist.md` 5 SCP가 **실패 유형(방어용)**이라면,
> 본 5축은 **통과 기준(인증용)** — 양면 보강.
> <!-- origin: autopus-adk TRUST 5 (Tested/Readable/Unified/Secured/Trackable) | merged: 26/04/18 -->

## 5축 매핑표

| 5축 | 영문 | 검증 항목 | 우리 도구 | 자동화 hook |
|----|------|---------|---------|-------------|
| **검(Tested)** | Tested | 단위/통합 테스트 ≥80% / 엣지·경쟁 케이스 / 회귀 방지 | g-stack `/qa`, pytest, npm test | PostToolUse(Write) `typecheck.sh` |
| **읽(Readable)** | Readable | 명확한 명명 / 단일 책임 / ≤300줄 / 주석 최소화 | code-analyzer, simplify | (수동) `/health` |
| **일(Unified)** | Unified | 포맷·임포트·린트 표준화 / 일관 패턴 / DRY | eslint/black/ruff | PostToolUse(Write) typecheck 일부 |
| **안(Secured)** | Secured | OWASP / 인젝션 / 시크릿 X / 권한 체크 | `/cso`, `/codex:adversarial-review` | PostToolUse(Write|Edit) `security-scan.sh` |
| **추(Trackable)** | Trackable | 의미있는 로그 / 에러 컨텍스트 / 결정 영속성 / 참조 추적 | gap-detector, `/lore-commit` | Stop hook `harsh-critic-stop.sh` |

> **명명 주의**: 단어 단독 사용 금지. 항상 **검(Tested)** 형식으로 영문 병기.

## 통과 게이트 — 5축 모두 충족 시 PASS

```
검: 테스트 실행 증거 + 통과율 ≥80%
읽: 단일 책임 위반 0건 + 함수 ≤50줄 권고
일: 린트 에러 0 + 포맷 통과
안: /cso WARN 이상 0건 + 시크릿 grep 0건
추: 핵심 결정에 /lore-commit 또는 mempalace drawer 1건+
추: 리뷰 코멘트마다 근거(rule 파일 / 테스트 / 외부 표준) 1건 이상 인용 — 인용 없으면 M5 위반
```

**1축이라도 FAIL → 머지 금지**. user-eye E1(거짓완료)·H1(떠넘기기) 규칙과 직결.

## 자동화 우선 (사용자 선호: hook 자동 발동)

| 5축 | 자동 발동 시점 | hook |
|----|--------------|------|
| 검 | PostToolUse(Write) 즉시 | `typecheck.sh` (async) |
| 안 | PostToolUse(Write|Edit) 즉시 | `security-scan.sh` (async) |
| 추 | Stop 시 완료 주장 검증 | `harsh-critic-stop.sh` |
| 읽·일 | 수동 (`/health`, `/review`) — 향후 hook 후보 | — |

읽·일 축은 현재 수동. 같은 파일 ≥300줄 또는 린트 에러 누적 감지 시 hook 추가 검토.

## 5 SCP × 5축 교차표

| SCP (실패) | 방어 | 5축 (통과) | 인증 |
|-----------|------|----------|------|
| SCP-1 조기종료 | 요구사항 1:1 매핑 | 검 | 테스트 통과 |
| SCP-2 컨텍스트열화 | /compact 30분 | 일 | 일관성 검증 |
| SCP-3 복잡도회피 | 축소 시 사용자 승인 | 읽 | 단일 책임 |
| SCP-4 책임분산 | 직접 결정 | 추 | 결정 영속성 |
| SCP-5 검증연극 | tool call 증거 | 검 + 안 | 실증 |

## 회고 분류 태그 (retrospective-engine 연동)

```
[5축-검 FAIL] 테스트 미실행 → SCP-5 검증연극 + 5축-검 미달
[5축-안 FAIL] /cso 미실행 + 시크릿 노출 → SCP-3 + 5축-안 미달
```

축별 빈도 추적 → 가장 약한 축에 자동화 hook 추가 검토.

## 위반 시 — harsh-critic 연동

5축 FAIL은 harsh-critic.md의 다음 항목과 매핑:
- 검 FAIL → E1(거짓완료) / E2(검증위장)
- 안 FAIL → E4(누적교훈재발) (보안 누적 교훈 위반 시)
- 추 FAIL → M3(형식적 사과 — 결정 영속성 없이 "다음에 조심") + M5(근거 없는 취향 리뷰)

## 리뷰 코멘트 표준 포맷
<!-- origin: mafia-codereview-harness side-effect pattern | merged: 26/04/26 -->

리뷰어(`/review`, `/codex:review`, plan-eng-review 등)는 각 코멘트를 6필드로 구조화:

```
- 위치: file.ts:42
- 근거: rules/X.md L23 또는 OWASP A02
- 내용: 무엇이 문제인가
- 제안: 구체 수정안
- side effect: 이 수정으로 발생하는 부작용/리스크
- 제안 이유: side effect를 감수하고도 권하는 이유
```

`근거` / `side effect` / `제안 이유` 누락 시 → harsh-critic M5 트리거.
trivial 1줄 수정(낮은 우선순위)은 `side effect` / `제안 이유` 면제 가능.

## 참조
- `service-completion-checklist.md` — 5 SCP (실패 유형)
- `harsh-critic.md` — 위반 대응 3단계
- `commands/lore-commit.md` — 추 축 보강 도구 (Phase 4)
