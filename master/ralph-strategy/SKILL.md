---
name: ralph-strategy
model: sonnet
description: |
  (MASTER) 반복 최적화 전략 수립. 목표/metric/target 정의 + progress.json 상태 모델 + 정체 대응.
  실제 반복 실행은 공식 ralph-loop 플러그인(Stop 훅 기반)이 담당한다.
  이 스킬은 "무엇을 반복할 것인가"를 결정하고,
  /ralph-loop 플러그인은 "어떻게 반복할 것인가"를 실행한다.
  
  트리거: "반복 전략", "최적화 계획", "ralph 계획", "정체 분석",
  "랄프 전략", "최적화 탐색", "반복 개선 계획"
  
  정체 2회+같은 에러 → model 승격 (haiku→sonnet→opus) + problem-solver 5Whys
  정체 3회 → unbounded-engine 재진입
  정체 5회 → 사용자에게 목표/metric 재정의 요청
model: sonnet
effort: high
---

# 랄프 루프 (Ralph Loop) — 자율 반복 실행 스킬

## 핵심 철학

> "처음부터 완벽하게 만들려 하지 마라. 루프가 알아서 개선한다."
> — Geoffrey Huntley의 Ralph Wiggum 기법

이 스킬은 Anthropic 공식 Claude Code 플러그인(ralph-wiggum)의 핵심 원리를
**Claude.ai 웹 채팅 + 코드 실행 환경**에서 구현한 것이다.

**3대 원칙:**
1. **파일 기반 상태 관리** — 진행 상황을 progress.json에 저장 (컨텍스트 의존 X)
2. **결정론적 실패 활용** — 실패는 예측 가능하고, 다음 반복의 학습 데이터가 됨
3. **명확한 완료 조건** — 수치/검증 가능한 기준이 있어야 루프가 의미 있음

---

## Phase 0: 적합성 진단 (Gate Check)

사용자의 요청을 받으면 **반드시 먼저** 아래 체크리스트로 랄프 루프 적합성을 판단하라.

### 적합성 판단 매트릭스

| 기준 | ✅ 적합 | ❌ 부적합 |
|------|---------|-----------|
| 완료 조건 | 수치/자동 검증 가능 | "좋은 느낌" 같은 주관적 기준만 존재 |
| 반복 가치 | 다른 접근법이 여러 개 존재 | 정답이 하나뿐인 단순 질문 |
| 상태 추적 | 중간 결과를 파일로 저장 가능 | 순간 판단만 필요 |
| 소요 시간 | 단일 턴으로 불충분 | 한 턴에 끝나는 간단한 작업 |

### 적합한 작업 유형

- **파라미터 최적화**: 트레이딩 전략 백테스트, 모델 하이퍼파라미터 탐색
- **코드 개발**: TDD 기반 기능 구현, 리팩토링, 버그 수정
- **데이터 분석**: 여러 가설을 순차 검증하는 탐색적 분석
- **문서 품질 개선**: 반복 리뷰를 통한 점진적 품질 향상
- **크롤링/스크래핑 개발**: 타겟 사이트 구조에 맞춘 반복 조정
- **프롬프트 엔지니어링**: 프롬프트 반복 개선으로 최적 결과 도출
- **알고리즘 설계**: 여러 접근법을 시도하며 성능 비교

### 부적합한 작업 → 안내 후 일반 응답

- 단순 질문/답변 (예: "파이썬에서 리스트 정렬하는 법")
- 1회성 문서 생성 (예: "이메일 초안 써줘")  
- 주관적 판단만 필요한 작업 (예: "이 디자인 어때?")
- 외부 API/실시간 데이터가 필수인 작업

### 부적합 판정 시 응답 템플릿

```
이 작업은 랄프 루프보다 일반 응답이 더 효율적입니다.

📋 이유: [구체적 이유]
💡 대안: [더 적합한 접근법 제안]

바로 작업을 시작할까요?
```

---

## Phase 1: 미션 브리핑 (정보 수집)

적합성 통과 후, 루프 실행에 필요한 정보를 수집한다.
**한 번에 3개 이하 질문** 원칙을 지키되, 아래 항목이 모두 확보될 때까지 진행한다.

### 필수 수집 항목

| 항목 | 설명 | 예시 |
|------|------|------|
| **목표 (Goal)** | 최종적으로 달성해야 할 것 | "승률 65% 이상 파라미터 조합 발견" |
| **완료 조건 (Exit Criteria)** | 수치/검증 가능한 종료 기준 | "테스트 통과율 100% + 린트 에러 0" |
| **탐색 범위 (Scope)** | 시도할 수 있는 접근법/변수 범위 | "EMA 기간 5/10/20/50/200 조합" |
| **최대 반복 수 (Max Iterations)** | 비용/시간 상한 | 기본값: 10 |
| **입력 데이터** | 분석할 파일, 코드베이스, 참고자료 | 업로드된 파일 또는 기존 코드 |

### 정보 부족 시 질문 우선순위

1순위: 목표와 완료 조건이 불명확한 경우
```
랄프 루프를 시작하려면 몇 가지 확인이 필요합니다:

1. 🎯 최종 목표: 이 작업이 "성공"이려면 구체적으로 어떤 상태여야 하나요?
2. ✅ 완료 기준: 숫자나 자동 검증이 가능한 조건이 있나요?
   (예: 승률 65% 이상, 테스트 전체 통과, 에러 0건 등)
3. 🔄 최대 반복: 몇 번까지 시도해볼까요? (기본 10회)
```

2순위: 목표는 있으나 범위가 넓은 경우
```
목표가 명확합니다! 범위를 좁히기 위해:

1. 📐 어떤 변수/접근법을 시도해볼까요?
2. 🚫 이미 시도해서 안 됐던 방법이 있나요?
```

---

## Phase 2: 루프 초기화

정보가 충분하면 progress.json을 생성하고 루프를 시작한다.

### progress.json 구조

```python
import json, os
from datetime import datetime, timezone, timedelta

KST = timezone(timedelta(hours=9))

progress = {
    "mission": {
        "goal": "[사용자가 정의한 목표]",
        "exit_criteria": [
            {"id": 1, "description": "[조건1]", "met": False},
            {"id": 2, "description": "[조건2]", "met": False}
        ],
        "max_iterations": 10,
        "scope": "[탐색 범위 설명]"
    },
    "status": "IN_PROGRESS",
    "current_iteration": 0,
    "iterations": [],
    "best_result": None,
    "created_at": datetime.now(KST).isoformat(),
    "updated_at": datetime.now(KST).isoformat()
}

PROGRESS_FILE = "/home/claude/ralph_progress.json"
with open(PROGRESS_FILE, "w") as f:
    json.dump(progress, f, ensure_ascii=False, indent=2)
```

---

## Phase 3: 반복 실행 (Core Loop)

**이것이 랄프 루프의 심장이다.** 매 반복(iteration)은 아래 5단계를 따른다.

### 반복 1회 = 5단계 사이클

```
┌─────────────────────────────────────────┐
│  STEP 1: 상태 로드 (progress.json 읽기) │
│              ↓                           │
│  STEP 2: 전략 선택 (이전 실패 기반)      │
│              ↓                           │
│  STEP 3: 실행 (코드 실행 / 분석 수행)    │
│              ↓                           │
│  STEP 4: 검증 (완료 조건 체크)           │
│              ↓                           │
│  STEP 5: 기록 (결과 → progress.json)     │
│              ↓                           │
│  완료 조건 충족? ──YES──→ 🏁 Phase 4     │
│       │ NO                               │
│       └──→ STEP 1로 복귀                 │
└─────────────────────────────────────────┘
```

### STEP 1: 상태 로드

```python
with open(PROGRESS_FILE, "r") as f:
    progress = json.load(f)

current = progress["current_iteration"]
past_attempts = progress["iterations"]

# 이전 반복에서 학습한 교훈 추출
lessons = [it["lesson_learned"] for it in past_attempts if it.get("lesson_learned")]
failed_approaches = [it["approach"] for it in past_attempts if not it["criteria_met"]]
```

### STEP 2: 전략 선택

이전 실패를 기반으로 **반드시 다른 접근법**을 선택해야 한다.
같은 접근을 두 번 시도하는 것은 금지.

전략 선택 로직:
1. `failed_approaches` 목록 확인 → 이미 시도한 방법 제외
2. 이전 반복의 `lesson_learned` 참고 → 학습된 방향으로 조정
3. `best_result`가 있으면 → 그 근처에서 미세 조정 (exploitation)
4. `best_result`가 없으면 → 넓게 탐색 (exploration)

### STEP 3: 실행

실제 작업을 수행한다. 작업 유형에 따라:

- **코드 개발** → 코드 작성/수정 후 테스트 실행
- **데이터 분석** → 계산/시각화 수행 후 결과 확인  
- **파라미터 탐색** → 조합 적용 후 성능 측정
- **문서 개선** → 수정 적용 후 품질 체크

코드 실행이 가능한 경우 반드시 bash_tool 또는 코드 실행 도구를 활용하라.
"아마 이럴 것이다" 같은 추측 대신 **실제 실행 결과**를 기준으로 판단하라.

### STEP 4: 검증

완료 조건을 하나씩 체크한다.

```python
results = {
    "iteration": current + 1,
    "approach": "[이번에 시도한 접근법 설명]",
    "result_summary": "[결과 요약]",
    "metrics": {},  # 수치 결과
    "criteria_checks": [],  # 각 완료 조건별 통과 여부
    "criteria_met": False,  # 전체 통과 여부
    "lesson_learned": "[이번 반복에서 배운 것]",
    "next_suggestion": "[다음에 시도할 방향]",
    "timestamp": datetime.now(KST).isoformat()
}

# 각 exit_criteria 검증
all_met = True
for criterion in progress["mission"]["exit_criteria"]:
    passed = evaluate_criterion(criterion, results["metrics"])
    results["criteria_checks"].append({
        "id": criterion["id"],
        "description": criterion["description"],
        "passed": passed
    })
    if not passed:
        all_met = False

results["criteria_met"] = all_met
```

### STEP 5: 기록

```python
progress["current_iteration"] += 1
progress["iterations"].append(results)
progress["updated_at"] = datetime.now(KST).isoformat()

# 최고 결과 갱신
if is_better_than(results, progress["best_result"]):
    progress["best_result"] = results

# 종료 판정
if results["criteria_met"]:
    progress["status"] = "COMPLETE"
elif progress["current_iteration"] >= progress["mission"]["max_iterations"]:
    progress["status"] = "MAX_ITERATIONS_REACHED"

with open(PROGRESS_FILE, "w") as f:
    json.dump(progress, f, ensure_ascii=False, indent=2)
```

---

## Phase 4: 종료 및 보고

### 정상 완료 (COMPLETE)

```
🏁 랄프 루프 완료!

📊 실행 요약
━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 반복 횟수: {n}회
최종 상태: ✅ 모든 완료 조건 충족

🎯 완료 조건 달성 현황
{각 조건별 ✅/❌ 상태}

📈 최종 결과
{best_result 상세}

💡 핵심 학습
{iterations에서 추출한 주요 교훈들}

📁 산출물
{생성된 파일 목록}
```

### 최대 반복 도달 (MAX_ITERATIONS_REACHED)

```
⚠️ 최대 반복 횟수({max})에 도달했습니다.

📊 현재까지 최선의 결과
{best_result 상세}

❌ 미충족 조건
{아직 통과하지 못한 조건들}

🔍 시도한 접근법 요약
{각 iteration의 approach 목록}

💡 다음 단계 제안
1. max_iterations를 늘려서 계속 진행
2. 완료 조건을 조정
3. 탐색 범위를 변경
4. 수동으로 best_result를 기반으로 마무리

계속 돌릴까요? (Y: 10회 추가 / N: 현재 결과로 마무리)
```

---

## 사용자 인터랙션 규칙

### 반복 중 진행 보고 (매 반복 완료 시)

```
🔄 반복 {n}/{max} 완료

접근법: {approach}
결과: {한 줄 요약}
조건 충족: {통과 수}/{전체 수}
최고 기록: {best_result 요약}

→ 다음 반복 진행 중...
```

이 보고를 출력한 후, 사용자 입력을 기다리지 않고 바로 다음 반복을 진행하라.
**단, 사용자가 "중지", "멈춰", "스톱", "cancel" 등을 입력하면 즉시 중단한다.**

### 사용자 개입 포인트

아래 상황에서만 사용자에게 질문한다:
1. 3회 연속 동일한 에러 패턴 → 방향 전환 필요 여부 확인
2. 최대 반복의 70% 도달 (예: 10회 중 7회) → 계속 여부 확인
3. 예상치 못한 에러로 실행 불가 → 문제 보고 및 대안 제시

### 사용자가 "계속" 입력 시

progress.json을 로드하고 중단된 지점부터 이어서 실행한다.
새 대화에서도 progress.json이 존재하면 자동으로 이전 상태를 복원한다.

---

## 산출물 관리

### 반복 중 생성되는 파일 구조

```
/home/claude/ralph_workspace/
├── progress.json          ← 루프 상태 (핵심)
├── iteration_01/
│   ├── result.json        ← 이 반복의 상세 결과
│   └── [작업별 산출물]    ← 코드, 데이터, 차트 등
├── iteration_02/
│   └── ...
└── final/                 ← 최종 산출물 (Phase 4에서 생성)
    └── [최종 결과물]
```

### 최종 산출물 제출

루프 완료 시, 최종 결과물은 프로젝트의 `작업진행/` 폴더에 저장한다.
(Claude.ai 환경에서는 `/mnt/user-data/outputs/`로 복사하고 `present_files`로 제공.)
파일명에는 한국시간 기준 `YYMMDDTHHMM_` 접두사를 포함한다.
예: `260404T0142_최적화결과.md`

---

## 프롬프트 템플릿 (references/prompt-templates.md 참조)

다양한 작업 유형별로 최적화된 프롬프트 구조가
`references/prompt-templates.md`에 정의되어 있다.

사용자의 작업 유형을 파악한 후 해당 템플릿을 참조하여
mission 객체를 구성하라.

---

## 고급: 멀티턴 연속 실행 전략

Claude.ai 웹 채팅에서는 하나의 턴에서 무한 루프를 돌릴 수 없다.
따라서 다음 전략을 사용한다:

### 전략 1: 단일 턴 최대 활용 (기본)

하나의 응답에서 **가능한 한 많은 반복**을 실행한다.
코드 실행 도구 호출 횟수 제한에 걸리기 전까지 연속 실행.
각 반복이 끝날 때마다 progress.json 업데이트.

### 전략 2: 자동 연속 요청 (사용자 협조)

턴이 끝날 때 아래 메시지를 출력하고, 사용자가 "계속"을 입력하면 이어간다:

```
⏸️ 이번 턴에서 {n}회 반복 완료. 진행률: {완료 조건 달성률}%
현재 최선: {best_result 요약}

💬 "계속" 입력 시 다음 반복을 이어갑니다.
💬 "결과" 입력 시 현재까지의 결과를 정리합니다.
💬 "조정 [내용]" 입력 시 조건/범위를 변경합니다.
```

### 전략 3: 청크 분할 (대규모 작업)

탐색 범위가 매우 넓은 경우, 범위를 청크로 나눠서 각 턴에서 하나의 청크를 처리한다.

```
전체 범위: EMA 조합 25개
  → 턴 1: 조합 1~5 탐색
  → 턴 2: 조합 6~10 탐색
  → ...
```

---

## 주의사항

1. **같은 접근을 두 번 시도하지 마라** — failed_approaches 리스트를 반드시 확인
2. **추측하지 마라** — 코드 실행이 가능하면 반드시 실행해서 확인
3. **progress.json은 매 반복마다 즉시 저장** — 중간에 끊겨도 복구 가능
4. **사용자 시간을 아껴라** — 불필요한 질문 없이, 자율적으로 판단하고 진행
5. **비용 의식** — max_iterations 내에서 효율적으로 탐색 (무작위 X, 체계적 탐색)

## DON'T
- progress.json 없이 반복 — 이전 결과 참조 불가, 같은 시도 반복
- 변경 없이 재실행 — 결과 동일. 매 반복 최소 1가지 변경 필수
- 10회+ 무한 반복 — max_iterations 설정 + 정체 시 사용자 보고

## DO
- 목표와 metric을 루프 시작 전에 명확히 정의
- 3회 연속 정체 시 unbounded-engine으로 방향 전환 제안
- 최종 보고에 "다음에 시도할 것" 포함
