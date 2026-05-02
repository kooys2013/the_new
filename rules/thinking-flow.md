---
paths:
  - "**/*"
---
# 사고 흐름 (Thinking Flow)

## 스킬 매핑

| 단계 | 스킬 | 핵심 질문 | 발동 조건 |
|------|------|-----------|-----------|
| 메타질문 | unbounded-engine | "이게 진짜 문제인가?" | 새 프로젝트, 방향 전환, 2회+ 실패 |
| 기획 | planning-generator | "무엇을, 왜, 어떤 순서로?" | 신규 기능, 아키텍처 결정 |
| 문제해결 | problem-solver | "근본 원인? 5 Whys" | 버그, 장애, 병목 |
| 연구 | research-pipeline | "선례/근거?" | 기술 선택, 라이브러리 비교 |
| 자율반복 | ralph-strategy | "좋은 결과까지 돌려" | 최적화, 파라미터 탐색 |
| 검증 | verification-pipeline | "Go/No-Go" | 배포 전, 설계 리뷰 |
| 회고 | retrospective-engine | "뭘 배웠나?" | 스프린트 종료, 기능 완료 |

## 축약 모드 (MemPalace [M] 태그 포함)

| 상황 | 경로 |
|------|------|
| 단순 버그 | [M]실수검색 → 문제해결 → 수정 → [M]실수저장 |
| 소규모 기능 | [M]유사기획검색 → 기획 → bkit PDCA → /review |
| 중대규모 기능 | [M]유사기획검색 → "한방에 개발" → [M]성장일지 |
| 기술 의사결정 | [M]과거결정검색 → 메타질문 → 연구 → [M]결정저장 |
| 최적화 | [M]전략이력검색 → 연구 → ralph-strategy → 검증 |
| 장애 대응 | 문제해결 → 회고 → [M]DAKI저장 |
| 스프린트 종료 | retro → [M]과거회고비교 → CLAUDE.md → [M]DAKI저장 |
| 배포 전 검증 | "한방에 검증" |
| 코드 수정 직후 | [M]유사실수검색 → /verify (자가검증, L0~L4 자동·L5만 컨센트) → FAIL 시 problem-solver |

## 도구 선택

```
"뭘 만들지 정리"   → planning-generator → bkit PDCA Plan
"코드 작성"        → bkit PDCA Do
"전부 알아서 해"   → unbounded "한방에 개발"
"만든 거 검토"     → g-stack /review
"보안 괜찮은지"    → g-stack /cso
"왜 안 되지"       → problem-solver
"배포 전 검증"     → unbounded "한방에 검증"
"코드 수정 완료"    → /verify (자가검증, L0~L4 자동·L5 컨센트)
"방금 수정/고쳤어"  → /verify
"이거 됐나/잘 됐나" → /verify
"이번 주 회고"     → retrospective-engine → g-stack /retro
"도리님 원리 확인" → search_dory / search_principle (dory-knowledge MCP)
"전략 카드 판단"   → search_dory → 도리님 렌즈(✅/⚠️/❓) → 백테 그리드 설계
"IDEA 채굴"        → /mentor-mine dory → /strategy-objectify
```

---

## v3 검증 흐름 (2605010914)

| 상황 | 경로 |
|------|------|
| 새 모듈 시작 전 | test-process → test-design → 코드 작성 → /verify |
| 자금 직결 변경 후 | /verify → coverage-gate → mutation-test → trading-safety-tester → multi-judge |
| 자연어 산출물 검증 | multi-judge (J1+J3 기본, 엄격 시 J2) → deb-bundler |
| 백테스트 코드 변경 | /verify (backtest_engine.py 자동 게이트 X) — 사용자 차트 튜닝 흐름 보호 |

## v3 도구 선택

```
"테스트 계획"     → test-process
"TC 만들어"       → test-design
"의도대로 됐어?"  → vv-separator
"커버리지 보강"   → coverage-gate
"변형 테스트"     → mutation-test
"property test"   → fuzz-test
"프롬프트 회귀"   → llm-eval-suite
"교차 심사"       → multi-judge
"추적/replay"     → trajectory-tracker
"거래 안전"       → trading-safety-tester
```

---

## v4 코딩·의사결정·자가발전 흐름 (2605011041)

| 상황 | 경로 |
|------|------|
| 새 기능 (3+ 파일, backtest 제외) | plan-mode-router (Opus Plan) → spec-driven-coder → 구현 → coding-eval-suite |
| 중요 결정 (아키텍처/전략) | decision-helper → Cynefin 분류 → sdg-6-elements → pre-mortem |
| 편향 우려 결정 | decision-helper → devils-advocate → wrap-decision |
| 구현 확신 추적 | coding-confidence-tracker (구현 전) → 실제 결과 기록 (구현 후) |
| 분기 회고 (심층) | retrospective-engine → double-loop-quarterly (governing variable 선택) |

## v4 도구 선택

```
"계획 먼저"       → plan-mode-router
"spec 먼저"       → spec-driven-coder
"코드 품질"       → coding-eval-suite
"갈림길/결정"     → decision-helper
"사전 부검"       → pre-mortem
"반론 검토"       → devils-advocate
"Brier 점수"      → confidence-calibration
"이중루프 회고"   → double-loop-quarterly
"하네스 진화"     → auto-mutation-pipeline
"DORA 메트릭"     → dora-reporter
```
