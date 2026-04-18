<!-- last-updated: 26/04/17 -->
---
description: Sonnet(실행) + Opus(자문)를 단일 /v1/messages 턴 안에서 결합하는 Advisor 패턴
paths:
  - "**/*"
---

# Advisor Strategy (Sonnet + Opus 단일 턴)

> 실행은 Sonnet/Haiku, 판단은 Opus — 단일 API 호출 안에서 executor가 advisor를 **도구처럼 호출**.
> <!-- origin: claude.com/blog/the-advisor-strategy | merged: 26/04/17 -->

## 1. 왜 필요한가

| 기존 | 한계 |
|------|------|
| Sonnet 단독 | 아키텍처·보안 판단에서 Opus 대비 품질 하락 |
| Opus 전면 전환 | 비용·사용량 과다 (90%+는 단순 실행) |
| 수동 /model 전환 | 턴 경계 기준 — 같은 작업 안에서 판단만 Opus에 묻기 불가 |

**Advisor**: executor(Sonnet/Haiku)가 복잡한 판단 지점에서만 Opus를 호출 → 대부분 작업은 저렴, 결정 지점만 frontier.

## 2. 공식 벤치마크 (블로그 기준)

- **SWE-bench Multilingual**: Sonnet+Opus advisor = Sonnet 단독 대비 **+2.7pp**, 태스크 비용 **-11.9%**
- **BrowseComp**: Haiku+Opus advisor = **41.2%** vs Haiku 단독 **19.7%** (>2배)
- **가격**: Haiku+Opus 조합이 Sonnet 단독 대비 성능 -29%, 비용 -85%

## 3. API 스펙

### 베타 헤더
```
anthropic-beta: advisor-tool-2026-03-01
```

### 도구 등록 (executor 요청에 tools 배열로)
```python
response = client.messages.create(
    model="claude-sonnet-4-6",              # executor
    tools=[
        {
            "type": "advisor_20260301",
            "name": "advisor",
            "model": "claude-opus-4-6",      # advisor
            "max_uses": 3,                   # 호출 상한
        },
        # ... 기존 도구들
    ],
    messages=[...]
)
```

- `type`: `advisor_20260301` (도구 타입 상수)
- `model`: advisor 모델 (현재 `claude-opus-4-6`)
- `max_uses`: executor가 advisor를 부를 수 있는 최대 횟수 (비용 보호)

### 과금
- executor 토큰 → executor 요율
- advisor 토큰 → Opus 요율
- 합산 비용이 Opus 단독 대비 훨씬 낮음

## 4. 사용 트리거 (WHEN → Advisor)

| 작업 유형 | Advisor 사용 | 이유 |
|----------|-------------|------|
| 구현 + 아키텍처 결정 동시 | ✅ | Sonnet 구현, Opus가 설계 판단만 |
| 구현 + 보안 고려 | ✅ | Sonnet 코드, Opus가 취약 패턴 감지 |
| 대규모 리팩토링 | ✅ | Sonnet 실행, Opus가 의존성 영향 추론 |
| 브라우저 자동화 + 복잡 판단 | ✅ (Haiku+Opus) | Haiku 클릭/입력, Opus가 다음 액션 결정 |
| 순수 코딩 (단순 CRUD) | ❌ | Sonnet 단독으로 충분 |
| 순수 전략/설계 | ❌ | Opus 단독 |
| 반복 루프 (ralph-loop) | ⚠ 조건부 | 루프 전체는 haiku/sonnet, 전환 지점만 advisor |

## 5. 사용량 가드 상호작용

`model-strategy.md §2` 사용량 구간 적용:
- GREEN (0~60%): Advisor 자유
- YELLOW (60~80%): Advisor OK, 단 `max_uses` ≤ 2 권장
- ORANGE (80~90%): Advisor 자제, 순수 Sonnet 권장
- RED (90%+): Advisor 금지 (Opus 토큰 소비 과다)

## 6. 에스컬레이션 내 위치

`model-strategy.md §4 교차검증 에스컬레이션`의 **3.5차** 단계:
```
1차 sonnet 실패
  → 2차 sonnet 재시도 실패
    → [3.5차] Advisor (sonnet + opus advisor) ← 신규
      → 3차 opus 전면 전환
        → 4차 /codex 교차검증
          → unbounded-engine 재진입
```

**3.5차를 먼저 시도하는 이유**: opus 전면 전환은 비용·사용량 부담이 큰데, 대부분의 "sonnet 2회 실패"는 판단 지점 1~2개만 Opus가 필요한 경우. Advisor가 그 구간을 저비용으로 커버.

## 7. Claude Code CLI 지원 상태

- 현재 CLI에서 `advisor_20260301` 도구 자동 등록 여부: **확인 필요** (research-pipeline Phase 8 감시 항목)
- CLI 미지원 시 대안: Agent tool로 Opus 서브에이전트 위임 (`Task(model="opus")`) + 결과를 메인 턴에 주입 → 유사 효과, 단일 호출은 아님
- 공식 지원 시: 이 규칙의 §3 코드를 hooks/skill 자동 생성 템플릿으로 이관

## 8. 비트리거 (사용 금지 구간)

- 단일 파일 1줄 수정
- 이미 해결 패턴이 `accumulated-lessons.md`에 있는 유형
- 사용자가 명시적으로 "Sonnet만" 지정한 세션
- ralph-loop 수십 회 호출 (max_uses 고갈 방지)

## 9. 교훈 축적

Advisor 사용 후 회고(retrospective-engine)에서:
- Advisor가 실제로 유효했나? (Sonnet 단독 대비 결정 품질 차이)
- `max_uses` 적정값은? (남용 or 부족)
- `accumulated-lessons.md`에 유형별 교훈 1줄 기록
