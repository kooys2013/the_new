---
description: 설계-구현 Drift 예산 — OpenAPI breaking / 아키텍처 규칙 / GO v2 CPCV DSR
paths:
  - "go-v2/backend/**/*.py"
  - "**/openapi*.yaml"
  - "**/openapi*.yml"
---

# Drift Budget

> 설계와 구현의 괴리를 **PostToolUse 시점에 경량 감지**하고 fit-escalation-ladder에 매핑.
> 핵심 훅: `drift-sentinel.sh` / 핵심 스킬: `drift-sentinel` / 베이스라인: `~/.claude/_cache/drift/baseline.json`.

## ALWAYS

- ALWAYS: OpenAPI breaking change는 **명시적 승인** 없이 커밋 금지 (PR 본문 `BREAKING:` 표시)
- ALWAYS: 아키텍처 규칙(레이어 간 import 방향) 위반 **zero**
- ALWAYS: GO v2 전략 코드 실거래 branch merge 전 **CPCV DSR ≥ 0.95** 검증 (Phase 2에서 자동화)
- ALWAYS: `baseline.json` 수정은 사용자 승인 + 이력 보관 (`baseline.json.{timestamp}.bak`)

## NEVER

- NEVER: `baseline.json` 자동 수정 / 훅이 사용자 승인 없이 overwrite
- NEVER: CPCV 미실행 전략을 실거래 브랜치에 merge
- NEVER: oasdiff/pytestarch 미설치 핑계로 drift 무시 — sha256 폴백이라도 **변경 감지**는 필수
- NEVER: critical severity를 warn으로 임의 강등

## WHEN...THEN

- WHEN `.yaml` 파일(OpenAPI) 수정 THEN: `drift-sentinel.sh`가 sha256 변경 감지 + oasdiff 있으면 diff 요약
- WHEN breaking change 감지 (method 삭제 / required field 추가) THEN: severity=critical → fit-escalation-ladder `hook` 단계
- WHEN 레이어 규칙 위반 (예: domain에서 infra import) THEN: severity=warn → `block` 단계
- WHEN GO v2 `backend/engine/*.py` 수정 THEN: drift-sentinel이 CPCV 권고 statusMessage
- WHEN info 3회 누적 THEN: 주간 회고에서 `drift-budget` 재평가

## 심각도 매핑 (fit-escalation-ladder 연동)

| Drift 심각도 | 판정 기준 | 에스컬레이션 |
|---|---|---|
| info | 비-breaking 변경 (additive) | warn (4주 지속 시) |
| warn | potentially-breaking (description 변경 등) | block (8주 지속 시) |
| critical | breaking (method/required 삭제, 응답 타입 변경) | hook (즉시) |

## baseline.json 구조

```json
{
  "version": 1,
  "created_at": "2026-04-18T12:00:00Z",
  "openapi": {
    "openapi.yaml": "sha256:abc123..."
  },
  "architecture": {
    "layers": ["domain", "application", "infrastructure"],
    "forbidden_imports": {"domain": ["infrastructure"]}
  },
  "go_v2": {
    "strategy_cpcv_required": true,
    "dsr_threshold": 0.95
  }
}
```

## 메타데이터 규칙

- `[DRIFT-LESSON]`: accumulated-lessons에서 drift 관련 교훈 태그
- baseline 수정 시 반드시 `[DRIFT-LESSON]`로 근거 기록 (회피 가능성 차단)
