---
description: file:// HTML 리포트가 백엔드 자원에 접근하는 단일 계약 — CORS 함정 영구 차단
paths:
  - "_report/**/*.html"
  - "**/_report/**/*.html"
  - "**/HTML리포트*/**/*.html"
---

# Report HTML × Backend Contract

> 일회성 HTML 리포트(`_report/HTML리포트[P]/*.html`)는 file:// 로 열린다.
> 브라우저는 file:// origin에서 localhost 다른 포트 직접 fetch 시 CORS 차단.
> 이 규칙이 영구 차단책.

## ALWAYS

- ALWAYS: 백엔드 데이터는 **FastAPI(8001) /api/* 만** 사용
- ALWAYS: SQL 조회는 `/api/db/exec?query=...` 프록시 (read-only, FastAPI가 서버측 9000 접근)
- ALWAYS: 헬스 카드 1순위로 `/api/freshness` 행 — stale=true 시 재시작 명령 즉시 노출
- ALWAYS: fetch 실패 시 HTTP 코드 + 에러 메시지 + 다음 액션 명시

## NEVER

- NEVER: HTML에서 `http://localhost:9000` (QuestDB) 직접 호출
- NEVER: HTML에서 `http://localhost:8812` (PG-wire) 직접 호출
- NEVER: HTML에서 `http://localhost:9009` (ILP) 직접 호출
- NEVER: catch 블록에서 "—"/"N/A"/"연결안됨" 단독 출력 — 원인 분류(CORS/stale/down) + 복구 힌트 필수

## 표준 fetch 헬퍼 (모든 리포트 HTML 상단 inline 의무)

```javascript
const API = 'http://localhost:8001';

async function backendFetch(path, opts = {}) {
  try {
    const r = await fetch(API + path, opts);
    if (!r.ok) return { ok: false, code: r.status, hint: `HTTP ${r.status} — /api/freshness 확인` };
    return { ok: true, data: await r.json() };
  } catch (e) {
    return { ok: false, code: 0, hint: `fetch 실패 — uvicorn(8001) 미기동? bash start.ps1` };
  }
}

async function dbQuery(sql) {
  return backendFetch('/api/db/exec?query=' + encodeURIComponent(sql));
}
```

## WHEN...THEN

- WHEN HTML 리포트 신규 작성 + 백엔드 데이터 필요 THEN: 위 헬퍼 inline + freshness 카드 + /api/db/exec 사용
- WHEN 헬스 카드 freshness가 stale=true THEN: 다른 모든 행 무시하고 "재시작" 안내 1순위 노출
- WHEN /api/db/exec 응답에 query 에러 THEN: error 메시지 + 입력 쿼리 그대로 화면 노출

## 자기 검증 (HTML 작성 후 체크리스트)

- [ ] HTML 어디에도 `localhost:9000` `localhost:8812` `localhost:9009` 문자열 없음
- [ ] 모든 fetch가 `API` 상수 경유 (즉 8001)
- [ ] 헬스 카드 1순위가 freshness
- [ ] catch 블록에 hint 메시지 명시
