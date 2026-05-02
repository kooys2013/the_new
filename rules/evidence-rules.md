---
description: Evidence Rules — 모든 자동화/리포트 출력의 근거 인용 6 게이트 (E1-E6)
paths:
  - "_cache/codex-automations/**"
  - "hooks/codex-daily-activity.sh"
  - "hooks/ci-failure-auto-triage.sh"
  - "hooks/dependency-drift-monitor.sh"
  - "hooks/performance-regression-tracker.sh"
  - "skills/review/SKILL.md"
  - "skills/manual-writer/SKILL.md"
  - "skills/retrospective-engine/SKILL.md"
  - "skills/drift-sentinel/SKILL.md"
---

# Evidence Rules — 6 게이트 (E1-E6)

> "주장에는 인용을, 부재에는 라벨을, 추측에는 등급을."
> 모든 자동화 출력(standup·CI triage·dep drift·growth·release notes·회고)은 이 6 게이트를 통과해야 한다.
> 위반 시 → `harsh-critic.md` E1(거짓완료) 또는 H3(근거 없는 규칙) 매핑.

---

## §1. 6 게이트 정의

### E1 — Cite Source (출처 인용)
**규칙**: 사실 주장에는 SHA / PR# / file:line / log timestamp 중 1개+ 인용 필수.

| 주장 유형 | 필수 인용 | 예시 |
|----------|----------|------|
| 코드 변경 | commit SHA 또는 PR# | `commit:abc1234` / `PR#42` |
| 파일 위치 | file:line | `backend/orders.py:42` |
| 로그 이벤트 | timestamp + 소스 | `log[2026-04-25T09:00 ci-runner]` |
| 측정값 | metric source + ts | `obs.jsonl:event=skill-call ts=...` |
| 외부 정보 | URL + access date | `[Anthropic blog 2026-04](url)` |

**위반**: "구현했다" / "버그를 고쳤다" 같은 인용 없는 단정.
**대응**: harsh-critic E1 (거짓완료 가능성 점검) → 인용 추가 또는 "Unknown"(E2) 적용.

---

### E2 — Mark Unknown (부재 명시)
**규칙**: 정보가 없거나 확인 불가하면 **"Unknown"** 또는 **"N/A — reason"** 으로 명시. 추측으로 채우지 마라.

**좋은 예**:
```
- 영향 범위: Unknown (CI 로그 보존 기간 초과)
- 회귀 시점: N/A — 측정 데이터 부재
```

**나쁜 예** (위반):
```
- 영향 범위: 약 5개 모듈 정도일 것 같음  ← 추측 + 미인용
- 회귀 시점: 지난주쯤                    ← 모호 + 미인용
```

**대응**: 추측 → "Unknown" 치환 + E5(no-data action) 동반.

---

### E3 — Verification Tier (검증 등급)
**규칙**: 모든 인사이트·진단·결론에 등급 라벨 1개 부착.

| 등급 | 정의 | 예시 |
|------|------|------|
| **observed** | 직접 측정·로그·diff 확인 | `[observed] tests/auth.spec.ts:42 가 실패함 (CI run #123)` |
| **suspected** | 간접 추론 (정황 증거) | `[suspected] auth.ts:88의 토큰 만료 처리 누락이 원인일 가능성` |
| **inferred** | 논리 도출 (직접 증거 없음) | `[inferred] 동일 패턴이 user-svc에도 존재할 것` |

**위반**: 등급 없는 단정 ("X가 원인이다"). 특히 `inferred`를 `observed`로 격상.
**대응**: 라벨 부착 또는 한 단계 강등.

---

### E4 — Impact Backing (영향 주장 뒷받침)
**규칙**: "이 변경이 X에 영향" / "성능 Y% 개선" 같은 영향 주장에는 PR / test / metric 1개+ 인용.

**좋은 예**:
```
영향: standup 생성 시간 -40% (PR#42 before/after benchmark, observed)
영향: 회귀 가능성 (suspected, 인용: tests/order.spec.ts 미존재)
```

**나쁜 예** (위반):
```
영향: 전체 시스템 안정성 향상  ← 측정 부재 + inferred 미라벨
영향: 사용자 경험 크게 개선     ← 정량 부재
```

**대응**: 정량 측정 추가 또는 "Unknown" + E5 next-step.

---

### E5 — No-data Action (데이터 부재 시 후속 액션)
**규칙**: "측정값 없음 / 로그 부재" 명시 시 **반드시 next-step 1개+ 동반**. 단순 부재 보고 금지.

**좋은 예**:
```
- 회귀 측정: no measurements found
  → next-step: obs.jsonl 주간 rotate 누락 여부 점검 (`hooks/obs-rotate.sh`)
- CI 로그: log retention expired
  → next-step: GitHub Actions logs retention 90일로 확장 검토
```

**나쁜 예** (위반):
```
- 회귀 측정: 데이터 없음.    ← next-step 부재
```

**대응**: next-step 추가 또는 보고 항목 자체 삭제.

---

### E6 — Tight Scope (범위 엄수)
**규칙**: 응답은 질문/태스크 범위 내. 부풀림 금지.

**위반 패턴**:
- 질문: "어제 standup 만들어" → 응답에 향후 30일 로드맵 포함 ❌
- 태스크: "CI 실패 triage" → 응답에 무관한 의존성 권고 포함 ❌
- 보고서 길이가 SCP-3 (복잡도 회피)을 가리는 부풀림 ❌

**좋은 예**:
- 요청 범위만 응답 + 추가 사항은 "scope-out: ..." 섹션에 별도 표기
- 추가 가치 발견 시 별도 next-step 제안 (현재 보고서에 섞지 않음)

**대응**: 범위 외 내용 제거 또는 "scope-out" 분리.

---

## §2. 출력 템플릿 매크로

모든 자동화 출력 파일(`_cache/codex-automations/*.md`)의 **헤더에 필수 포함**:

```markdown
# {제목} — {YYMMDD}

> Evidence Rules (E1-E6) 준수.
> 인용 형식: `commit:abc1234` / `PR#42` / `file.ts:L42` / `log[ISO-8601]` / `[url](title)`
> 라벨: `[observed]` / `[suspected]` / `[inferred]`
> 부재: `Unknown` / `N/A — {reason}` (E5 next-step 동반)

## Summary
- ...

## Findings
1. **{핵심 발견}** [observed]
   - 인용: commit:abc1234, file.ts:L42
   - 영향: ...

## Unknowns / Next Steps
- {항목}: Unknown — {next-step}

## Scope-out (참고)
- {범위 외 발견 사항, 별도 처리}
```

---

## §3. ALWAYS / NEVER

- **ALWAYS**: 자동화 출력 헤더에 §2 매크로 포함
- **ALWAYS**: 사실 주장 1건 = 인용 1건 이상
- **ALWAYS**: 부재(Unknown/N/A) 보고 시 next-step 동반
- **ALWAYS**: 검증 등급 라벨(observed/suspected/inferred) 부착
- **NEVER**: 인용 없는 영향 주장 (E4 위반)
- **NEVER**: 추측을 단정으로 표현 (E2/E3 위반)
- **NEVER**: 응답 부풀림으로 누락을 가리기 (E6 + SCP-3 위반)
- **NEVER**: `inferred` 결과를 `observed` 라벨로 격상

---

## §4. 위반 시 매핑

| 위반 게이트 | harsh-critic 매핑 | 대응 |
|------------|-------------------|------|
| E1 (인용 부재) | **E1 거짓완료** | BLOCK + 인용 추가 후 재제출 |
| E2 (추측을 단정) | **H3 근거 없는 규칙** | 경고 + Unknown 치환 |
| E3 (등급 미부착) | **H3 근거 없는 규칙** | 경고 + 라벨 부착 |
| E4 (영향 인용 부재) | **H3 근거 없는 규칙** | 경고 + 측정/인용 추가 |
| E5 (next-step 부재) | **M3 형식적 사과** | 로그 + next-step 추가 |
| E6 (범위 부풀림) | **H2 범위 축소** (역방향) | 경고 + scope-out 분리 |

> 본질: E1-E4 위반은 user-eye **HIGH**, E5-E6은 **MEDIUM**.

---

## §5. 운영 정책 (3-Level)

> `prompt-refiner-policy.md` Level 사다리와 동형. 14일 silent 관찰 후 승격.

| Level | 동작 | 승격 조건 |
|-------|------|----------|
| **L0 (현재)** | 자기 검증만 — 헤더 매크로 필수 | T+14일 위반율 ≤5% |
| **L1** | obs-bus가 위반 시 statusMessage 힌트 | T+30일 수정률 ≥30% |
| **L2** | PostToolUse 훅이 위반 출력 차단 | 수동 승격 (apply-daily-fit.sh P) |

승격 결정 = `_cache/harness/mutation-YYMMDD.json` 대기열 → 사용자 승인. **L3 영구 금지** (ruin risk).

---

## §6. 관련 문서 + §7. 자가 검증

**참조**: `harsh-critic.md` / `service-completion-checklist.md` / `user-eye.md` / `prompt-refiner-policy.md` / `daily-fit-contract.md`

**자가 검증 체크리스트** (자동화 출력 1건 작성 직후):
- [ ] §2 헤더 매크로 포함 / [ ] 사실 주장 인용 (E1) / [ ] Unknown 명시 (E2) / [ ] observed/suspected/inferred 라벨 (E3) / [ ] 영향 주장 인용 (E4) / [ ] 부재 시 next-step (E5) / [ ] 범위 엄수 (E6)

7항목 모두 "예"가 아니면 → harsh-critic 진입 + 수정 후 재제출.
