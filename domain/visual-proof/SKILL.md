---
name: visual-proof
description: |
  스크린샷 기반 UI 자동 검증 + 사용 설명서 생성 스킬 v3.5
  듀얼 모드: ① 개발 보고서 (캡처→4신호→Evaluator→수정→보고) ② 사용 설명서 (캡처→어노테이션→DITA 매뉴얼)
  Playwright MCP (143 디바이스) + ADB (Android) + xcrun (iOS).
  Generator-Evaluator 분리, JSON 상태, 한 페이지씩, fix-before-build.

  TRIGGER when: "스크린샷", "캡처", "visual proof", "UI 확인", "화면 검증",
  "스크린샷 보고서", "모바일에서 확인", "디바이스별 캡처", "visual-proof",
  "사용 설명서", "프로그램 매뉴얼", "사용법 PDF",
  프론트엔드(CSS/컴포넌트/레이아웃) 변경 완료 후
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
  - mcp__playwright__browser_close
  - mcp__playwright__browser_wait_for
  - mcp__playwright__browser_console_messages
  - mcp__playwright__browser_network_requests
---

# Visual Proof Report v3.5 — UI 검증 + 사용 설명서 생성

> 2가지 모드: ① 개발 보고서 (캡처→검토→수정→보고) ② 사용 설명서 (캡처→어노테이션→매뉴얼 생성)
> 기존 /screenshot, /qa-report 등은 이 스킬로 대체.
> user-eye.md 규칙이 전역 rules에 반영됨.

## 사전 요구
```bash
claude mcp add --scope user playwright npx @playwright/mcp@latest
claude mcp add --scope user a11y npx a11y-mcp
```

## ═══ MODE A: 개발 보고서 (기존 v3.0 전체) ═══

"스크린샷 보고서", "UI 확인", "캡처해서 보고서" 등의 요청 시 실행.

### Anthropic 하네스 5대 원칙

1. **Generator-Evaluator 분리** — 수정한 쪽이 "잘 됐다" 판단하지 않는다
2. **JSON 상태 추적** — `.visual-proof-progress.json`으로 세션 간 진행 보존
3. **fix-before-build** — 이전 페이지 문제 수정 완료 후 다음 페이지 진행
4. **한 페이지씩 처리** — 컨텍스트 초과 방지, 페이지마다 4신호 수집
5. **세션 종료 프로토콜** — 미완료 시 JSON 저장 후 `[VP-PAUSE]` 출력

### 3-Tier 캡처

- **Tier 1**: 웹앱 → Playwright MCP (143 디바이스)
- **Tier 2**: Expo `--web` / Flutter `--web-renderer html` → Playwright
  주의: Flutter html 렌더러 필수, CanvasKit은 DOM 접근 불가
- **Tier 3A**: Android → `adb exec-out screencap -p` + Maestro
- **Tier 3B**: iOS → xcrun simctl (macOS) / Playwright 에뮬레이션 (기타)

자동 판별: package.json→T1, expo/rn→T2, pubspec→T2, build.gradle→T3A, xcodeproj→T3B

### Phase 0: 탐지 & 초기화
프로젝트 루트 스캔 → Tier 자동 판별 → `.visual-proof-progress.json` 생성

### Phase 1: 환경 준비
Tier에 따라 dev server 기동, 라우트 수집

### Phase 2: 페이지별 캡처 + 4가지 신호 수집 (한 페이지씩)
1. **스크린샷** — 디바이스별 fullPage 캡처
2. **콘솔 에러** — `browser_console_messages`로 JS 에러 수집
3. **네트워크 실패** — `browser_network_requests`로 4xx/5xx 감지
4. **접근성 위반** — a11y MCP로 axe-core 기반 위반 목록 수집

기본 프리셋 (standard): Desktop 1440x900 + iPhone 13 390x844 + Galaxy S21 360x800

### Phase 3: Evaluator 채점 (4기준 × 5점, 3점 미만 → 수정)

| 기준 | 1점 | 3점 | 5점 |
|------|-----|-----|-----|
| 레이아웃 무결성 | 완전히 깨짐 | 일부 어긋남 | 완벽 |
| 타이포그래피 일관성 | 폰트/크기 혼재 | 부분 일관성 | 완전 일관 |
| 시각적 일관성 | 색상/간격 제각각 | 대체로 일관 | 완전 일관 |
| 접근성 | WCAG 위반 다수 | 일부 위반 | 완전 준수 |

### Phase 3.5: User-Eye 검사
> user-eye.md 규칙 적용. 전역 rules/user-eye.md에 반영됨.
- **EXTREME** → 즉시 BLOCK
- **HIGH** → 수정 후 재채점
- **MEDIUM** → 보고서 기록

### Phase 4: 자동 수정 (Generator)
수정마다 개별 git commit (`fix(visual): [페이지] [증상] 수정`)

### Phase 5: fix-before-build
다음 페이지 전 이전 수정 재검증 → 3점+ 확인

### Phase 6: HTML 보고서 생성
base64 인라인 단일 HTML. 파일명: `YYMMDDHHMM_VisualProof_{프로젝트}.html` → `_report/`

## ═══ MODE B: 사용 설명서 생성 (v3.5 신규) ═══

"사용 설명서 만들어줘", "프로그램 매뉴얼", "사용법 PDF" 등의 요청 시 실행.
manual-writer 스킬과 세트로 동작.

### 스크린샷 규격 (골드 스탠다드)

| 항목 | 규격 | 근거 |
|------|------|------|
| 해상도 | 2× DPR (Retina) | GitHub docs 기준 |
| 포맷 | PNG (텍스트 선명) | JPEG 아티팩트 방지 |
| 어노테이션 | #FF0000 빨간색 — 사각형, 화살표, 번호 원 | Rackspace 가이드 |
| alt 텍스트 | 125~140자, 목적 중심 | WCAG 2.2 |
| 다크모드 | 라이트/다크 2버전 | Heroshot 방식 |
| 파일명 | `{기능}_{디바이스}_{테마}.png` | 대규모 관리용 |
| 저장 경로 | `docs/screenshots/{desktop,mobile}/{light,dark}/` | 구조화 |

### 스크린샷 매니페스트 (manifest.json)

```json
{
  "project": "MyApp",
  "baseUrl": "http://localhost:3000",
  "chapters": [
    {
      "title": "시작하기",
      "pages": [
        {
          "path": "/login",
          "filename": "login-page",
          "description": "로그인 화면",
          "viewports": ["desktop", "mobile"],
          "themes": ["light", "dark"],
          "annotations": [
            {"selector": "#email", "type": "number", "label": "1", "note": "이메일 입력"},
            {"selector": "button[type=submit]", "type": "arrow", "note": "로그인 버튼"}
          ]
        }
      ]
    }
  ]
}
```

### Step B1: 매니페스트 생성
라우트 스캔 → 사용자 확인 → manifest.json 자동 생성

### Step B2: 배치 캡처
매니페스트 기반 모든 페이지 × 디바이스 × 테마 캡처. Playwright fullPage + 2× DPR.

### Step B3: 어노테이션
매니페스트 annotations 정의에 따라 #FF0000 콜아웃 추가.

### Step B4: DITA Task 구조로 문서 생성
각 기능: 개요 → 사전조건 → 단계(스크린샷) → 예상결과 → 문제해결

### Step B5: PDF/HTML 변환
```bash
pandoc manual.md -o manual.pdf --pdf-engine=weasyprint --css=style.css --toc --toc-depth=3
```

### 듀얼 출력
| 산출물 | 대상 | 내용 |
|--------|------|------|
| 사용자 매뉴얼 | 최종 사용자 | 단계별 가이드 + 어노테이션 + 문제해결 |
| 개발 보고서 | 개발팀 | git diff + 채점표 + 이슈 목록 |

## ═══ 공통 ═══

### 디바이스 프리셋
| 프리셋 | 디바이스 |
|--------|---------|
| minimal | Desktop + iPhone 13 |
| standard | Desktop + iPhone 13 + Galaxy S21 (기본) |
| full | Desktop + iPhone 13 mini + 15 Pro Max + Galaxy + iPad |

### DO / DON'T
| 금지 | 결과 |
|------|------|
| Generator가 자기 수정을 "잘 됐다" 판단 | 문제 놓침 |
| Markdown으로 상태 관리 | 모델 임의 수정 |
| 모든 페이지 한번에 | 컨텍스트 초과 |
| QA 없이 "완료" 선언 | EXTREME BLOCK |
| JPEG로 스크린샷 저장 | 텍스트 아티팩트 |
| 어노테이션 색상 임의 변경 | 일관성 파괴 |
| 스크린샷 alt 텍스트 생략 | 접근성 위반 |

### 스킬 연동
- 이상 → problem-solver (5 Whys)
- 비교 → verification-pipeline (Go/No-Go)
- 반복 → ralph-loop (iteration)
- 3번+ 같은 문제 → unbounded-engine (재설계)
- 스프린트 종료 → retrospective-engine
- **사용 설명서 → manual-writer (DITA + PDF)**

### 참고
- Anthropic 하네스: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Playwright MCP: https://playwright.dev/docs/getting-started-mcp
- GitHub 스크린샷 정책: https://docs.github.com/en/contributing/writing-for-github-docs/creating-screenshots
- Diátaxis: https://diataxis.fr/
- shot-scraper: https://github.com/simonw/shot-scraper
- Heroshot: https://www.heroshot.sh/

### 체크리스트
- [ ] 모든 디바이스 캡처 완료?
- [ ] 4가지 신호 수집?
- [ ] Evaluator 3점+ 전 기준?
- [ ] user-eye 통과?
- [ ] fix-before-build 완료?
- [ ] HTML 보고서 _report/ 저장?
- [ ] (MODE B) 매니페스트 기반 전체 캡처?
- [ ] (MODE B) 어노테이션 규격 준수?
- [ ] (MODE B) DITA 5단계 완성?
