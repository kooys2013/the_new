<!-- origin: langgptai/awesome-claude-prompts (no automation) + custom barbell design | adapted: 26/04/19 -->
---
description: prompt-refiner 훅 운영 정책 — Level 0/1/2 단계 승격, 10% 샘플링 바벨, Ruin 방지
paths:
  - "hooks/**"
  - ".claude/**"
---

# Prompt-Refiner Policy

> "안멋진 프롬프트를 역질문으로 멋지게" — 단, UX 파괴(false-positive)를 막기 위한 **바벨 10%** 필수.

---

## §1. 왜 이 정책이 필요한가

`awesome-claude-prompts` 저장소는 실제 automation이 없음 (README 프롬프트 모음만). 사용자 요청 *"대충 넣어도 잘 돌아가는 구조"* 는 **직접 구축** 필요. 그러나 UserPromptSubmit 훅이 모든 프롬프트를 차단·수정하면 false-positive 로 UX 영구 손상 (ruin risk).

→ **바벨 전략**: 10% silent 샘플링 + 90% 관찰 없이 통과. 14일 관찰 후 단계 승격.

---

## §2. Level 단계 정의 (compiler warning 유추)

| Level | 동작 | 승격 조건 | 승격 전 단계 |
|-------|-----|----------|-------------|
| **Level 0 (기본)** | silent 로그만 — 사용자에게 영향 0 | FP rate ≤5% × 14일 | — |
| **Level 1** | statusMessage 힌트 — 훅이 추가 정보만 전달, 프롬프트 변경 없음 | 힌트 수락률 ≥30% × 30일 | Level 0 |
| **Level 2** | 역질문 suggestion — 사용자에게 명확화 질문을 **제안** (강제 아님) | 제안 수락률 ≥50% × 30일 | Level 1 |

**ALWAYS**: Level 0 → 1 승격은 **수동 승인** (`_cache/harness/mutation-*.json` 대기열 → 사용자 apply)
**NEVER**: Level 3 (강제 재작성) — ruin risk 너무 큼, 영구 금지

---

## §3. 훅 동작 명세 (Level 0)

### 입력
- UserPromptSubmit JSON (stdin)
- 필드: `prompt`, `session_id`, `cwd`

### 처리 (≤20ms 하드캡)
1. **샘플링 게이트**: `$RANDOM % 10 == 0` (10% 확률)
   - 90% → 즉시 `exit 0` (silent)
2. **지표 계산** (샘플링된 10%만):
   - `length` = prompt 글자수
   - `has_question` = `?` / `?` / `뭐` / `어떻게` / `왜` 포함 여부 (regex)
   - `ambiguity_score` = 0.0~1.0
     - 길이 < 20 글자: +0.3 (너무 짧음)
     - WH-word 없음: +0.2
     - "이거/저거/그거/대충/아무거나" 다의어: +0.3 (최대 3회)
     - "뭐/어떻게/왜/언제/어디" 있음: -0.2 (기본값 완화)
     - clamp [0.0, 1.0]
3. **로그 append**: `_cache/prompt-refine/YYMMDD.jsonl` 한 줄 추가
4. **exit 0** (성공은 침묵)

### 출력
- Level 0: `exit 0` (statusMessage 없음, stdout 없음)
- Level 1 (미래): statusMessage 힌트만
- Level 2 (미래): JSON `{additionalContext: "역질문 제안..."}`

---

## §4. 로그 스키마 (`_cache/prompt-refine/YYMMDD.jsonl`)

```jsonl
{"ts":"2026-04-19T23:45:12+09:00","session":"abc12345","prompt_hash":"8a3f2c1d","length":47,"has_question":false,"ambiguity_score":0.5,"sampled":true,"level":0}
```

**필드**:
- `ts`: ISO 8601 (Windows: PowerShell `Get-Date -Format o`)
- `session`: session_id 앞 8자
- `prompt_hash`: SHA-256 앞 8자 (개인정보 보호 — 원문 저장 금지)
- `length`: 프롬프트 글자 수
- `has_question`: bool
- `ambiguity_score`: 0.0~1.0
- `sampled`: 항상 true (샘플링 통과만 기록)
- `level`: 현재 Level (0/1/2)

**NEVER**: 프롬프트 원문 저장 금지 (해시만)
**ALWAYS**: 일간 rotate — `_cache/prompt-refine/YYMMDD.jsonl` 자동 분리
**ALWAYS**: 30일 경과 시 수동 archive 대상 (자동 삭제 안 함)

---

## §5. vibe-sunsang과의 관계 (독립 작동)

- vibe-sunsang은 `~/.claude/projects/*.jsonl` (Claude Code 네이티브 세션 로그) 소비
- prompt-refiner는 `_cache/prompt-refine/*.jsonl` (자체 로그) 생성
- **두 시스템은 독립** — 서로 간섭 없음
- 주간 회고 시 양쪽을 **교차 참조**하여 패턴 일치 여부 검증 (수동)

---

## §6. 승격 판정 절차

### T+14일 (Level 0 → 1 평가)
1. `_cache/prompt-refine/*.jsonl` 30 샘플 수동 판정
2. 각 샘플에 대해: "이 프롬프트는 실제로 모호했나?" Y/N 표기
3. FP rate = (score ≥0.5 인데 실제로는 명확한 프롬프트) / 전체 샘플
4. FP ≤5% → `_cache/harness/mutation-YYMMDD.json` 에 P(Promote) 코드 대기
5. 사용자가 `apply-daily-fit.sh P rules/prompt-refiner-policy.md` 승인 시 Level 1 활성

### 롤백 (언제든)
- `settings.json` `hooks.UserPromptSubmit[]` 에서 prompt-refiner 제거
- `_cache/prompt-refine/` 폴더는 보존 (사용자 자산)
- policy 파일은 `<!-- dormant:YYMMDD -->` 마커 추가

---

## §7. 연관 규칙

- `rules/daily-fit-contract.md` Layer 3 — reinforcer 매커니즘 (본 훅과 병렬)
- `rules/asset-lifecycle.md` — Level 승격 = P mutation, 참조 감지
- `rules/fit-escalation-ladder.md` — Level 0→1→2 사다리와 warn→block→hook 사다리 매핑
- `rules/user-eye.md` — EXTREME: "실제 데이터 없이 판단 생성 금지" → Level 0 관찰 기간 필수

---

## §8. ALWAYS / NEVER

- ALWAYS: Level 0 **14일** 관찰 후에만 승격 검토
- ALWAYS: 샘플링률 10% 고정 (증감 시 본 파일 수정 + mutation 기록)
- ALWAYS: 훅 실패 시 `exit 0` silent (세션 블로킹 금지)
- ALWAYS: 프롬프트 원문 저장 금지 (SHA-256 해시만)
- NEVER: Level 2 이상으로 "강제 재작성" 도입 (ruin risk)
- NEVER: 훅 실행 시간 >20ms (레이턴시 SLA)
- NEVER: 샘플링 게이트 우회 (모든 프롬프트 처리)
- NEVER: vibe-sunsang 로그 포맷을 본 훅 출력으로 덮어쓰기 (독립 유지)
