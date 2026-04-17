<!-- last-updated: 26/04/17 -->
---
description: vibe-sunsang 관찰 기반 DNA 강제화 단계 사다리
paths:
  - "**/*"
---

# FIT Escalation Ladder

> vibe-sunsang 6축(DECOMP/VERIFY/ORCH/FAIL/CTX/META) 관찰 결과에 따라 **점진 강제화**. 교훈 생명주기와 동일 구조.

## 4단계 사다리

```
[D+1] warn   — 경고 출력만 (현재 기본)
  │ 조건: 4주 연속 해당 축 개선 없음
  ▼
[D+28] block — 작업 차단 (exit 1)
  │ 조건: 8주 연속 같은 축 최약
  ▼
[D+56] hook  — 강제 실행 (PreToolUse/Stop 훅)
  │ 조건: 6개월 위반 0회
  ▼
archive      — 내면화 완료, 제거
```

## 축별 매핑

| 축 | warn 위치 | block 승격 | hook 승격 |
|---|---|---|---|
| DECOMP | session-briefing.sh 경고 | PreCompact 훅에서 Phase 1-D 강제 | UserPromptSubmit 마이크로태스크 검사 |
| VERIFY | harsh-critic-stop 경고 | Stop 훅 exit 1 (검증 없음 시) | PreToolUse(TodoWrite complete) block |
| ORCH | skill-quickref.md 참조 안내 | 키워드→스킬 자동 트리거 강제 | UserPromptSubmit 훅 키워드 라우팅 |
| FAIL | problem-solver 권고 | PreToolUse(Edit) 2회 실패 차단 | Stop 훅 3회실패 에스컬레이션 강제 |
| CTX | statusline ⚠ /compact | 60% 초과 시 Bash 차단 | UserPromptSubmit 파일지정 역질문 |
| META | SessionStart 브리핑 1줄 | 회고 미실행 시 세션 종료 차단 | 주간 retrospective 강제 |

## 자동 승격 판정

- `hooks/weekly-fit-analyzer.sh` 주간 실행 → 같은 축 4주 최약 → 승격 제안
- `hooks/apply-weekly-fit.sh A` → warn→block 패치 자동 적용
- 승격 후 4주간 효과 없으면 자동 롤백 제안

## 졸업 (archive)

- 6개월간 해당 hook 0회 발동 → 내면화 완료로 간주
- `monthly-fit-report.sh`가 자동 후보 제시
- 사용자 승인 후 `archive/` 이동

<!-- origin: fivetaku/vibe-sunsang@6-axis + kooys2013/the_new@lifecycle | merged: 26/04/17 -->
