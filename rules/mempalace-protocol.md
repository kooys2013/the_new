---
description: MemPalace 실수 방지 + 맥락 검색 프로토콜 (세션 시작/실수 발생/세션 종료)
paths:
  - "**/*"
---

# MemPalace 실수 방지 프로토콜

## 세션 시작 시

- WHEN: 새 작업 시작 THEN: `mempalace_search`로 해당 도메인의 과거 실수를 검색
  - 코딩 작업 → wing: `wing_mistakes`, room: `coding-bugs`
  - 트레이딩 작업 → wing: `wing_mistakes`, room: `trading-errors`
  - KORENO 작업 → wing: `wing_mistakes`, room: `koreno-lessons`
  - 하네스 작업 → wing: `wing_mistakes`, room: `harness-lessons`
- 검색 결과의 RULE 항목을 현재 세션의 컨텍스트에 로드

## 실수 발생 시

- ALWAYS: 실수 발견 즉시 `mempalace_add_drawer`로 기록 (아래 포맷 사용)
- ALWAYS: problem-solver로 근본 원인 분석 후 RULE 도출
- NEVER: "다음에 조심하겠다"로 끝내지 마라 — 반드시 ALWAYS/NEVER 규칙으로 변환

## 실수 기록 포맷

wing: `wing_mistakes`, room: `{도메인}-bugs|errors|lessons`

```
[MISTAKE] {날짜 YY/MM/DD} | {프로젝트} | {심각도: P0/P1/P2}
WHAT: {무슨 실수 — 한 줄}
WHY: {근본 원인}
FIX: {어떻게 고쳤는가}
RULE: {ALWAYS/NEVER/WHEN...THEN 형식 영구 규칙}
TAGS: {검색용 키워드 쉼표 구분}
```

## 실수 패턴 감지

- WHEN: 같은 room에서 같은 TAGS 실수가 3건+ THEN:
  → "이 실수가 반복됩니다. 구조적 개선 필요" 경고
  → unbounded-engine 재진입 제안

## 검색 우선순위 (작업 시작 시)

1. `wing_mistakes` — 실수 방지 (최우선)
2. 해당 프로젝트 wing — 맥락 복원
3. `wing_harness` — 하네스 교훈

## 검색 스킵 조건

- 단순 질문/답변 (1턴 완료)
- 이번 세션에서 같은 키워드로 이미 검색
- 컨텍스트 60% 초과 (검색 결과가 컨텍스트 부풀림)

## 환경 분기 (도구 가용성)

| 환경 | 사고 스킬 | MemPalace | 코딩 도구 |
|------|----------|-----------|----------|
| Claude Code | 7종 전체 | MCP 19 tools | g-stack+bkit+hooks |
| Claude.ai + MCP | 7종 전체 | MCP 19 tools | bash_tool 기반 |
| Claude.ai 기본 | 7종 전체 | CLI fallback | bash_tool 기반 |

- g-stack/bkit이 없는 환경 → 해당 도구 참조 건너뛰고 사고 스킬 + MemPalace + bash로 진행
- "도구가 없습니다" 에러 발생 시 환경 분기 적용
