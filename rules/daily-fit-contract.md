<!-- last-updated: 26/04/18 -->
---
description: Daily Fit Loop 1-B 계약 — Layer 1/2/3 제약, DNA mutation 4코드, Slack conditional
paths:
  - "hooks/**"
  - ".claude/**"
---

# Daily Fit Contract (일일 핏 계약)

> 자가발전 하네스의 일일 진화 사이클 — 경량 SessionStart(≤30s) + 심층 22:45 분석(≤5m) + PostToolUse reinforcer(≤100ms).
> 제안은 자동, **적용은 수동** (user-eye sovereignty).

## 1. 3-Layer 아키텍처 제약

| Layer | 트리거 | 제한 시간 | 실패 정책 |
|-------|--------|----------|----------|
| Layer 1 — check | SessionStart | ≤30s | silent exit 0 (세션 블로킹 금지) |
| Layer 2 — analyzer | Task Scheduler 22:45 | ≤5m 하드캡 | 타임아웃 시 부분 리포트 + 로그 기록 |
| Layer 3 — reinforcer | PostToolUse(Edit\|Write\|MultiEdit) | ≤100ms | silent exit 0 (Edit 체인 보호) |

## 2. ALWAYS

- ALWAYS: Layer 1은 **캐시 hit 우선** (`daily-fit-YYMMDD.json` 존재 시 박스 브리핑만)
- ALWAYS: Layer 2는 `_report/YYMMDDTHHMM_daily_fit.md` 생성 후 종료
- ALWAYS: DNA mutation 제안은 하루 **최대 1건** (우선순위 최상위만)
- ALWAYS: 제안은 `_cache/harness/mutation-YYMMDD.json`에 기록 후 `apply-daily-fit.sh`로만 적용
- ALWAYS: Layer 3 reinforcer는 파일명 정규식으로 먼저 필터링 (불필요 I/O 제거)

## 3. NEVER

- NEVER: Layer 1에서 외부 ping / docker / curl 실행
- NEVER: Layer 1/2가 `~/.claude/history.jsonl` 을 스킬·훅 호출 소스로 사용 (스키마 미보장)
- NEVER: DNA mutation을 자동 적용 (manual approval 필수)
- NEVER: `_report/` 30일 경과 분을 삭제 (rotate만, 보존 필수)
- NEVER: Layer 2가 22:45~23:00 창에서 `weekly-fit-analyzer.sh`(일요일 22:00)와 동시 실행 → 월요일~토요일만 정상, 일요일 자동 skip
- NEVER: `archive/` 폴더 자산을 Layer 1 캐시에 포함

## 4. DNA Mutation 4-코드

| 코드 | 풀네임 | 조건 | 승인 명령 |
|------|--------|------|----------|
| **P** | Promote | 룰 위반 0 + hook 발동 0이 60일 → archive 승격 **또는** `[reinforced:]` 3회 → 상위 티어 승격 | `apply-daily-fit.sh P <file>` |
| **D** | Demote | 적중률 <5% + 30일 참조 0 → dormant 강등 | `apply-daily-fit.sh D <file>` |
| **R** | Reevaluate | 상충 교훈 2건 or 적중률 전주比 -50% | `apply-daily-fit.sh R <file>` |
| **A** | Activate | dormant 자산에 최근 참조 발생 → resurrect | `apply-daily-fit.sh A <file>` |

**우선순위 점수** = (위반 빈도) × (심각도 E=3 / H=2 / M=1) + (일수 가중 0.01/day). 동점 시 P > D > R > A.

## 5. WHEN → THEN

- **WHEN** Layer 1이 3회 연속 >30s → **THEN** `harsh-critic.md` H 등급 위반 → 즉시 Layer 1 최적화
- **WHEN** Layer 2가 DNA mutation 0건을 7일 연속 제안 → **THEN** 임계값(60/150일) 완화 검토
- **WHEN** E/H 심각도 발견 3건 누적 → **THEN** Slack conditional 알림 (slack-notify.sh)
- **WHEN** `apply-daily-fit.sh` 실행 → **THEN** obs JSONL에 `dna-mutation` 이벤트 기록 (event, code, target, ts)
- **WHEN** archived 자산에 resurrect 요청 >2회/월 → **THEN** 150일 기준 재검토

## 6. Slack 알림 모드

| 모드 | 조건 | 설정 |
|------|------|------|
| always | 모든 Layer 2 실행 완료 | `DAILY_FIT_SLACK=always` |
| **conditional** (기본) | E/H 심각도 발견 시만 | `DAILY_FIT_SLACK=conditional` |
| never | 완전 침묵 | `DAILY_FIT_SLACK=never` |

## 7. GO v2 통합

- GO v2 (`go-v2/` 폴더 감지 시) → Layer 2가 CPCV DSR 분기 포함
- 그 외 cwd → GO v2 섹션 skip (리포트에 "N/A" 표기)
- 기본값 **separate** — 프로젝트 이동성 유지

## 8. 성공 지표 (T+30일)

| 지표 | 목표 | 측정 |
|------|------|------|
| Layer 1 중앙값 | ≤1.5s | SessionStart 훅 timing obs 이벤트 |
| Layer 2 중앙값 | ≤3m | Task Scheduler 실행 로그 |
| DNA 제안 빈도 | 주 3건+ | mutation-*.json 개수 |
| DNA 제안 수락률 | ≥30% | apply-daily-fit.sh 실행 대비 제안 비율 |
| archive 졸업 | 월 1건+ | `archive/` 폴더 증가율 |

## 9. 관련 파일

- `rules/asset-lifecycle.md` — 자산 상태 정의
- `rules/fit-escalation-ladder.md` — hook 강제화 사다리
- `skills/daily-fit-engine/SKILL.md` — Layer 2 심층 분석 skill
- `skills/asset-inventory/SKILL.md` — 자산 인벤토리 (보조)
- `hooks/2604181800_daily-fit-check.sh` — Layer 1
- `hooks/2604181801_daily-fit-analyzer.sh` — Layer 2
- `hooks/2604181802_lesson-reinforcer.sh` — Layer 3
- `hooks/_setup/apply-daily-fit.sh` — 승인 CLI
