---
description: 회고(retrospective-engine) 완료 후 MemPalace 동기화 규칙
paths:
  - "**/*"
---

# 회고-MemPalace 동기화 규칙

## retrospective-engine 완료 후 반드시

### 1. DAKI 결과 → drawer 저장
- wing: 해당 프로젝트 wing (wing_mgtg / wing_harness / wing_koreno / wing_side)
- room: `retro-{YYMMDD}`
- content: DAKI 전체 텍스트

### 2. Drop 항목 → 실수로 등록
- wing: `wing_mistakes`, room: `{도메인}-lessons`
- [MISTAKE] 포맷 적용

### 3. 과거 회고 비교
- 이전 세션의 Drop이 이번에 재발했는지 확인
- 이전 Add가 실제로 도입됐는지 확인

## 과거 회고 참조 (Phase 1 시)
```
mempalace_search "retro" --wing {프로젝트wing} --room retro-
```
최근 3건 로드 → 이중 루프 학습 데이터 기반 자동 트리거
