---
name: manual-writer
description: |
  7구조 매뉴얼 + 스크린샷 포함 프로그램 설명서 스킬 v2.5
  듀얼 모드: ① 7구조 매뉴얼 (스킬/도구/프로세스) ② 스크린샷 포함 사용 설명서 (DITA Task + PDF)
  Anthropic 하네스(Progressive Disclosure, Generator-Evaluator 분리) 반영.
  visual-proof v3.5와 세트: visual-proof가 캡처 → manual-writer가 문서 생성.

  TRIGGER when: "매뉴얼", "가이드", "문서화", "7구조", "manual",
  "사용법 정리", "레퍼런스 만들어", "문서 작성",
  "사용 설명서", "프로그램 매뉴얼", "사용법 PDF", "100페이지 매뉴얼"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_take_screenshot
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_resize
---

# Manual Writer v2.5 — 7구조 + 스크린샷 설명서

> 2가지 모드: ① 7구조 매뉴얼 (스킬/도구/프로세스) ② 스크린샷 포함 프로그램 설명서 (PDF)
> 기존 매뉴얼/가이드 커맨드는 이 스킬로 대체.
> visual-proof v3.5가 캡처한 스크린샷을 사용 설명서로 변환.

## Anthropic 하네스 원칙

1. **Progressive Disclosure**: SKILL.md에 프로세스만. 지식은 references/로 분리.
2. **Generator-Evaluator 분리**: 작성 ≠ 채점. 구조별 1~5점.
3. **하중 지지 가정 점검**: 각 구조에 "없으면 어떤 문제?" 명시.

## ═══ MODE A: 7구조 매뉴얼 (기존 v2.0 전체) ═══

"매뉴얼 만들어줘", "가이드 작성", "문서화해줘" 등의 요청 시 실행.

### 7구조 패턴

#### 구조 1: 개요표
ASCII 고정폭 표. 최상단. 필수: 이름, 한줄설명, 유형, 입출력, 의존성, 대체대상.
없으면? → Claude가 스킬 경계 오해.

#### 구조 2: 목차
2depth 이내. 7구조 순서 + 부록.
없으면? → 전체 파악 불가.

#### 구조 3: 사용예
복사 가능 프롬프트 3~6개. 유형별(기본/고급/에러대응).
없으면? → 트리거 방법 모름.

#### 구조 4: DO / DON'T
각 5개+. DON'T에 "→ [결과]" 필수.
없으면? → 안티패턴 반복.

#### 구조 5: Evals
입력 → 기대 → 판정. 4개+.
없으면? → 개선/퇴보 판별 불가.

#### 구조 6: 트리거 진단
거짓양성/거짓음성/충돌 3유형.
없으면? → 다른 스킬과 충돌.

#### 구조 7: 활용 아이디어
예상 밖 활용 3~5개.
없으면? → 잠재 가치 미발견.

### 실행 흐름 (MODE A)

Phase 0: 대상 파악 → 부족하면 최대 3개 역질문
Phase 1: 스켈레톤 → 7구조 빈 뼈대 → 사용자 확인
Phase 2: 구조별 채우기 (Generator)
Phase 3: 출력 형식 결정 (HTML/텍스트/PPT/PDF)
Phase 4: 품질 검증 (Evaluator, 구조별 1~5점, 3점 미만 → 재작성)
Phase 5: 세션 종료 (미완성 시 JSON 기록)

### Phase 4 상세: Evaluator

| 구조 | 3점 기준 |
|------|---------|
| 개요표 | ASCII 고정폭, 항목 7개+ |
| 목차 | 2depth, 전체 반영 |
| 사용예 | 3개+, 복사 가능 |
| DO/DON'T | 각 5개+, "→ 결과" 전부 |
| Evals | 4개+, 판정 기준 명확 |
| 트리거 | 3유형, 수정안 포함 |
| 활용 | 3개+, 예상 밖 포함 |

## ═══ MODE B: 스크린샷 포함 프로그램 설명서 (v2.5 신규) ═══

"사용 설명서 만들어줘", "프로그램 매뉴얼", "사용법 PDF", "100페이지 매뉴얼" 등의 요청 시 실행.
visual-proof v3.5의 MODE B와 세트로 동작.

### Diataxis 4유형 분류

매뉴얼의 각 섹션을 4유형 중 하나로 분류:
| 유형 | 목적 | 스크린샷 밀도 |
|------|------|-------------|
| 튜토리얼 | 학습. 처음부터 따라하며 배움 | 높음 (매 단계 캡처) |
| HOW-TO | 실행. 특정 목표 달성 방법 | 중간 (핵심 단계만) |
| 레퍼런스 | 참조. 설정, API, 기능 목록 | 낮음 (UI 위치만) |
| 설명 | 이해. 개념, 아키텍처, 배경 | 최소 (다이어그램) |

### DITA Task 구조

각 기능/페이지마다 5단계로 문서 생성:

```
## [기능명]

### 개요
이 기능은 [무엇을 하는가]. [왜 필요한가].

### 사전 조건
- [필요한 권한/상태]
- [선행 작업]

### 단계
1. [메뉴/위치]로 이동합니다.
   ![설명](screenshots/기능_desktop_light.png)

2. [입력/선택]합니다.
   ![설명](screenshots/기능_step2.png)

### 예상 결과
[정상 동작 시 화면/상태 설명]

### 문제 해결
| 증상 | 원인 | 해결 |
|------|------|------|
```

### 스크린샷 규격 (visual-proof와 통일)

| 항목 | 규격 |
|------|------|
| 해상도 | 2× DPR (Retina) |
| 포맷 | PNG |
| 어노테이션 | #FF0000 빨간색 — 사각형, 화살표, 번호 원 |
| alt 텍스트 | 125~140자, 목적 중심 |
| 파일명 | `{기능}_{디바이스}_{테마}.png` |

### 골드 스탠다드 참고 모델

| 모델 | 배울 점 |
|------|--------|
| Stripe docs | 문서가 제품의 일부 |
| GitHub docs | 스크린샷 정책 공개, #BC4C00 어노테이션 |
| Adobe Photoshop PDF | 500+페이지 PDF 매뉴얼 완성 형태 |
| Salesforce Trailhead | 단계별 스크린샷, 게이미피케이션 |

### 사용 설명서 생성 흐름

#### Step B1: 범위 정의
대상 프로그램 확인. manifest.json 읽기 또는 생성.
visual-proof 스크린샷 있으면 재활용.

#### Step B2: 목차 구성
manifest.json chapters 기반 또는 라우트 분석.
Diataxis 유형 태깅.

#### Step B3: 스크린샷 확보
visual-proof `docs/screenshots/`에 있으면 재활용.
없으면 → visual-proof MODE B 실행 요청.

#### Step B4: DITA Task 구조로 생성
한 챕터씩 생성 (컨텍스트 절약).

#### Step B5: PDF/HTML 변환
```bash
pandoc manual.md -o manual.pdf \
  --pdf-engine=weasyprint --css=manual-style.css \
  --toc --toc-depth=3
```
핵심 CSS: `figure { break-inside: avoid; }`

#### Step B6: 품질 검증
- 모든 단계에 스크린샷?
- 어노테이션이 텍스트와 일치?
- DITA 5단계 전부?
- PDF 단독 열림, 잘림 없음?

## ═══ 공통 ═══

### visual-proof와의 연동

```
visual-proof v3.5          manual-writer v2.5
─────────────────          ─────────────────
MODE A: 개발 보고서         MODE A: 7구조 매뉴얼
MODE B: 스크린샷 캡처       MODE B: 사용 설명서 PDF
        │                          │
        └─ docs/screenshots/ ─────→┘
```

| 요청 | 스킬 |
|------|------|
| "스크린샷 보고서" | visual-proof MODE A |
| "UI 캡처해서 매뉴얼" | visual-proof MODE B → manual-writer MODE B |
| "매뉴얼 만들어줘" (스킬) | manual-writer MODE A |
| "사용 설명서 PDF" | manual-writer MODE B |

### DO / DON'T
| DO | DON'T → 결과 |
|----|--------------|
| 7구조 전부 채우기 | 일부만 → 품질 불균형 |
| DON'T에 결과 명시 | 이유 없는 금지 → Claude 무시 |
| DITA 5단계 완성 | "문제 해결" 생략 → 사용자 막힘 |
| visual-proof 스크린샷 재활용 | 같은 화면 다시 캡처 → 낭비 |
| PNG 2× DPR | JPEG → 텍스트 아티팩트 |
| 한 챕터씩 생성 | 전체 한번에 → 컨텍스트 초과 |
| 코드 수정 금지 | 매뉴얼에서 코드 수정 → 역할 혼동 |

### 스킬 연동
- 대상 분석 → research-pipeline
- 문제 발견 → problem-solver
- PPT → pumeuiseo-generator
- 회고 → retrospective-engine
- 근본 재설계 → unbounded-engine
- UI 스크린샷 → visual-proof

### 참고
- Anthropic 하네스: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Diataxis: https://diataxis.fr/
- DITA: https://www.oasis-open.org/committees/dita/
- GitHub 스크린샷: https://docs.github.com/en/contributing/writing-for-github-docs/creating-screenshots
- Pandoc: https://pandoc.org/
- WeasyPrint: https://weasyprint.org/
- shot-scraper: https://github.com/simonw/shot-scraper
