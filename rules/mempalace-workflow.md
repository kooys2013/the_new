---
description: MemPalace 통합 워크플로 — 실수 방지 프로토콜 + 회고 동기화 + 성장 일지 규칙
paths:
  - "__on_demand_only__"
---

# MemPalace 통합 워크플로

> 원본 3파일 통합: mempalace-protocol.md + mempalace-retro-sync.md + mempalace-growth-log.md
> 원본 아카이브 위치: `rules/_archive/26-04-17/`

---

## Protocol: 실수 방지 + 맥락 복원

### 세션 시작 시

- WHEN: 새 작업 시작 THEN: `mempalace_search`로 해당 도메인의 과거 실수를 검색
  - 코딩 작업 → wing: `wing_mistakes`, room: `coding-bugs`
  - 트레이딩 작업 → wing: `wing_mistakes`, room: `trading-errors`
  - KORENO 작업 → wing: `wing_mistakes`, room: `koreno-lessons`
  - 하네스 작업 → wing: `wing_mistakes`, room: `harness-lessons`
- 검색 결과의 RULE 항목을 현재 세션의 컨텍스트에 로드

### 실수 발생 시

- ALWAYS: 실수 발견 즉시 `mempalace_add_drawer`로 기록 (아래 포맷 사용)
- ALWAYS: problem-solver로 근본 원인 분석 후 RULE 도출
- NEVER: "다음에 조심하겠다"로 끝내지 마라 — 반드시 ALWAYS/NEVER 규칙으로 변환

### 실수 기록 포맷

wing: `wing_mistakes`, room: `{도메인}-bugs|errors|lessons`

```
[MISTAKE] {날짜 YY/MM/DD} | {프로젝트} | {심각도: P0/P1/P2}
WHAT: {무슨 실수 — 한 줄}
WHY: {근본 원인}
FIX: {어떻게 고쳤는가}
RULE: {ALWAYS/NEVER/WHEN...THEN 형식 영구 규칙}
TAGS: {검색용 키워드 쉼표 구분}
```

### 실수 패턴 감지

- WHEN: 같은 room에서 같은 TAGS 실수가 3건+ THEN:
  → "이 실수가 반복됩니다. 구조적 개선 필요" 경고
  → unbounded-engine 재진입 제안

### 검색 우선순위 (작업 시작 시)

1. `wing_mistakes` — 실수 방지 (최우선)
2. 해당 프로젝트 wing — 맥락 복원
3. `wing_harness` — 하네스 교훈
4. **dory-knowledge MCP** — 전략/원리 작업 시 도리님 원문 참조 (GO 프로젝트 한정)

### 검색 스킵 조건

- 단순 질문/답변 (1턴 완료)
- 이번 세션에서 같은 키워드로 이미 검색
- 컨텍스트 60% 초과 (검색 결과가 컨텍스트 부풀림)

### 환경 분기 (도구 가용성)

| 환경 | 사고 스킬 | MemPalace | 코딩 도구 |
|------|----------|-----------|----------|
| Claude Code | 7종 전체 | MCP 19 tools | g-stack+bkit+hooks |
| Claude.ai + MCP | 7종 전체 | MCP 19 tools | bash_tool 기반 |
| Claude.ai 기본 | 7종 전체 | CLI fallback | bash_tool 기반 |

- g-stack/bkit이 없는 환경 → 해당 도구 참조 건너뛰고 사고 스킬 + MemPalace + bash로 진행
- "도구가 없습니다" 에러 발생 시 환경 분기 적용

---

## Retro Sync: 회고 완료 후 동기화

### retrospective-engine 완료 후 반드시

**1. DAKI 결과 → drawer 저장**
- wing: 해당 프로젝트 wing (wing_mgtg / wing_harness / wing_koreno / wing_side)
- room: `retro-{YYMMDD}`
- content: DAKI 전체 텍스트

**2. Drop 항목 → 실수로 등록**
- wing: `wing_mistakes`, room: `{도메인}-lessons`
- [MISTAKE] 포맷 적용

**3. 과거 회고 비교**
- 이전 세션의 Drop이 이번에 재발했는지 확인
- 이전 Add가 실제로 도입됐는지 확인

### 과거 회고 참조 (Phase 1 시)

```
mempalace_search "retro" --wing {프로젝트wing} --room retro-
```
최근 3건 로드 → 이중 루프 학습 데이터 기반 자동 트리거

---

## Growth Log: 성장 일지

### 자동 트리거

- WHEN: /compact를 2회+ 사용한 세션 종료 시 THEN: 성장 일지 작성 제안
- WHEN: 마일스톤 달성 감지 시 THEN: 성장 일지 작성
- WHEN: 사용자가 "오늘 정리", "성장일지", "뭐했지" 요청 THEN: 성장 일지 작성

### 성장 일지 포맷

```markdown
# 성장 일지 — {날짜} {프로젝트}

## 세션 요약
- 주요 작업: {한 줄 요약}
- 완료 여부: ✅ 완료 / 🔧 진행 중 / ❌ 차단됨

## 잘한 점 (Keep)
- {구체적 행동 + 근거}

## 반성 점 (Improve)
- {구체적 실수/비효율 + 원인}
- → RULE: {ALWAYS/NEVER 변환}

## 성장 포인트
- {이번 세션에서 새로 배운 것}
- {이전 실수를 이번에 방지한 사례}

## 방향성 체크
- 현재 방향이 올바른가? {판단 + 근거}
- 유성에게 확인받고 싶은 것: {질문/결정}

## 다음 세션 TODO
- [ ] {다음에 이어서 할 것}
```

### 성장 일지 저장

1. MemPalace: wing={프로젝트wing} / room=`growth-log`
2. 파일: `_report/YYMMDDTHHMM_growth_log.md`

### 성장 일지 작성 후

- 이전 성장 일지와 비교하여 성장 추세 한 줄 코멘트
- "유성에게 확인받고 싶은 것" 섹션 반드시 포함

---

## Knowledge Drawer 포맷 (v1.0, 26/04/18 — GBrain Compiled Truth 이식)

### 목적
원리·아키텍처·의사결정 같은 **정제된 지식**을 drawer에 구조화 저장한다.
대화 로그(기존 wing_mistakes / wing_mgtg 등)와 명확히 분리한다.

### Wing 구조
- wing: `wing_knowledge` (전용, 신설)
- hall: `hall_facts` (원리·결정) / `hall_discoveries` (새 발견) / `hall_advice` (권장사항)
- room: `{도메인}-{주제}` 예: `mgtg-p-theory`, `koreno-psm-12elements`, `harness-scp-protocol`

### Drawer 포맷 (필수 준수)

```markdown
---
type: principle | architecture | decision | pattern
title: {한 줄 제목}
tags: {쉼표 구분}
supersedes: {기존 drawer ID, 대체하는 경우}
references: {관련 drawer ID 쉼표 구분}
last_compiled: {YY/MM/DD}
---

## 현재 이해 (Compiled Truth)
{지금 시점의 **확정된 결론**. 추측·가설 금지.}
{새 증거 나오면 이 섹션 전체를 **재작성**한다. append 금지.}

---

## 증거 타임라인 (Append-Only)
- YY/MM/DD: {근거 + 출처}
- YY/MM/DD: {반례 or 업데이트 + 출처}
```

### 쓰기 규칙

- ALWAYS: 상단 재작성 시 `last_compiled` 필드 갱신 (YY/MM/DD 포맷)
- ALWAYS: 하단 타임라인은 **append-only** — 과거 항목 수정·삭제 금지
- ALWAYS: 상단을 뒤엎는 증거 발견 시 → 신규 drawer 생성 후 `supersedes: {기존 ID}` 지정, 기존 drawer는 유지
- NEVER: 대화 로그·실수 기록을 wing_knowledge에 쓰지 마라 (wing_mistakes 또는 프로젝트 wing으로)
- NEVER: Compiled Truth 섹션에 "아마도", "추정됨", "확인 필요" 표현 금지 — 확정만
- WHEN: 3건 이상의 타임라인 항목이 상단과 모순 THEN: 즉시 재작성 (stale-detector 훅 자동 알림)

### Typed Link 의미론

| 필드 | 의미 | 예시 |
|---|---|---|
| `supersedes` | 이 drawer가 기존 drawer를 대체함 | 새 SL 공식이 이전 SL 공식을 대체 |
| `references` | 이 drawer가 다른 drawer를 근거로 삼음 | P이론이 등배원리를 참조 |

### 검색·호출 패턴

```
# 기본: wing_knowledge 내 정제 지식 검색
mempalace_search "P이론 지지" --wing wing_knowledge

# 특정 타입만
mempalace_search "P이론" --wing wing_knowledge --room mgtg-p-theory

# supersedes 체인 추적 (이 drawer를 대체하는 최신본 찾기)
# → MCP 도구로 직접 지원되지 않으므로, references 필드 grep으로 수동 확인
```

### 자동 트리거 연동 (auto-triggers.md 참조)
- 전략 카드·PSM·횡전개 결정 시작 시 자동 검색
- last_compiled가 90일+ 미갱신 drawer는 stale-detector가 주간 알림

<!-- origin: garrytan/gbrain@compiled-truth+typed-links | merged: 26/04/18 -->
