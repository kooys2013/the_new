---
description: E2E 추적성 계약 — REQ/GO/KORENO ID 주입 체인 (프롬프트→코드→커밋→trace)
paths:
  - "__on_demand_only__"
---

# Traceability Contract

> 요구사항 ID가 프롬프트 → 코드 → 커밋 → trace까지 **자동 연쇄 주입**.
> 핵심 훅: `requirement-id-tagger.sh` (UserPromptSubmit) / 핵심 스킬: `traceability-weaver`.

## ALWAYS

- ALWAYS: 커밋 메시지에 `REQ-xxx` / `GO-xxx` / `KORENO-xxx` 중 하나 포함 (lore-commit-suggest 훅이 제안)
- ALWAYS: 신규 함수 docstring 첫 줄에 요구사항 ID 명시 (예: `"""REQ-042: 주문 검증 로직"""`)
- ALWAYS: PR 본문 상단에 관련 REQ/GO ID 나열
- ALWAYS: OpenAPI path operation의 `operationId`는 REQ ID를 포함 (예: `getOrder_REQ-042`)

## NEVER

- NEVER: orphan REQ (요구사항 언급만 있고 구현 없음) 1주 이상 방치
- NEVER: ID 없이 prod 브랜치 merge
- NEVER: 요구사항 ID를 uppercase 외 포맷으로 기재 (`req-42`, `Req_42` 금지 — 정규식 매칭 실패)

## WHEN...THEN

- WHEN 사용자 프롬프트에 `(REQ|GO|KORENO)-\d{3,}` 포함 THEN: `requirement-id-tagger.sh`가 additionalContext에 "컨텍스트: REQ-xxx" 주입
- WHEN 주입된 REQ가 traceability 매트릭스에 미등록 THEN: `traceability-weaver` 자동 제안
- WHEN 커밋 스테이징에 ID 없음 THEN: lore-commit-suggest가 최근 REQ 후보 제시
- WHEN OpenAPI `.yaml` 수정되고 operationId에 REQ ID 없음 THEN: drift-sentinel이 info 이벤트 기록

## 매트릭스 구조

`~/.claude/_cache/obs/traceability.jsonl` — 각 레코드 1줄:

```json
{"ts": "2026-04-18T12:00:00Z", "req_id": "REQ-042", "kind": "code", "file": "backend/orders.py", "symbol": "validate_order", "session": "pid-1234"}
```

`kind`: `prompt` / `code` / `commit` / `test` / `docstring`

## 메타데이터 규칙

- `[TRACE-LESSON]`: accumulated-lessons에서 추적성 관련 교훈 태그
- 90일간 `reinforced` 없는 매트릭스 항목은 stale 후보
