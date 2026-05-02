---
description: 백엔드 실패를 가짜 데이터/빈 catch로 가리는 silent failure 영구 차단 — GO v2 frontend 전용
paths:
  - "go-v2/frontend/**/*.tsx"
  - "go-v2/frontend/**/*.ts"
  - "_report/**/*.html"
---

# No Silent Fallback Contract

> "데이터가 알맹인데 알맹이가 없다"의 근원: 실패 시 그럴듯한 모양으로 무음 폴백.
> - HTML: `catch → "—"` (모양은 유지, 의미는 거짓)
> - 차트앱: `catch → generateMockKlines(2000)` (모양은 유지, 의미는 거짓)

## NEVER

- NEVER: production 코드 경로에서 `generateMockX()` / 가짜 시계열 / 무작위 데이터 생성
- NEVER: `catch { /* 무시 */ }` 또는 `catch {}` 빈 catch — 코멘트만 있어도 금지
- NEVER: HTTP 비-2xx를 정상 데이터처럼 처리하거나 try/catch로 감싸 무음 처리
- NEVER: 캐시 hit 후 백그라운드 fetch 실패를 사용자에게 미통지 (stale 마킹 의무)
- NEVER: WebSocket onerror/onclose 무처리 — heartbeat + state propagation 필수
- NEVER: API 클라이언트에서 HTTP 상태코드를 Error 메시지에만 담고 `err.status` 미보존

## ALWAYS

- ALWAYS: 데이터 컴포넌트는 명시적 상태 모델 hold (loading / live / stale-cache / backend-down)
- ALWAYS: catch는 사용자 가시 상태로 변환 + 마지막 성공 시각 표기
- ALWAYS: API 클라이언트는 HTTP 상태코드를 `(err as any).status = res.status` 로 보존
- ALWAYS: dev-only mock은 `import.meta.env.DEV` 가드로 tree-shake 처리
- ALWAYS: WS는 heartbeat(ping/pong) + exponential backoff + state callback 구현

## WHEN...THEN

- WHEN catch 블록 작성 THEN: 상태 변환 코드 1줄 이상 + 사용자 노출 경로 검증
- WHEN 모의 데이터 생성 함수 추가 THEN: 호출자가 모두 `import.meta.env.DEV` 가드 안인지 grep 확인
- WHEN 새 fetch 래퍼 작성 THEN: 응답 status 보존 + 본문 텍스트 첨부
- WHEN WS 클라이언트 작성 THEN: onerror 핸들러 + heartbeat 인터벌 + exponential backoff 의무

## 자기 검증 (구현 후 체크리스트)

- [ ] `grep -r "generateMock" src/` 결과가 모두 `import.meta.env.DEV` 가드 안인가?
- [ ] `grep -rn "catch {" src/` 결과가 0건인가?
- [ ] WS 코드에 `onerror`, `ping`/`heartbeat`, `backoff` 키워드 모두 있는가?
- [ ] dexie schema에 `meta` store + version key 있는가?
- [ ] TopBar에 BackendStatus 배지 포함되어 있는가?
