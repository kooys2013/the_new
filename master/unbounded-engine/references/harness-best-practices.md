# Harness Best Practices Reference

> 무한사고 셋업 모드에서 참조하는 Claude Code 하네스 베스트 프랙티스.
> 최신 공식 문서 기반으로 CLAUDE.md와 하네스 설정을 최적화한다.

---

## 공식 문서 링크 (최신 확인용)

| 주제 | URL | 핵심 |
|------|-----|------|
| **Best Practices** | https://code.claude.com/docs/en/best-practices | 전체 워크플로우 패턴 |
| **CLAUDE.md & Memory** | https://code.claude.com/docs/en/memory | CLAUDE.md 구조·계층·자동메모리 |
| **Hooks** | https://code.claude.com/docs/en/hooks | 자동화 훅 설정 |
| **Skills** | https://code.claude.com/docs/en/skills | 스킬 구조·호출 방식 |
| **Subagents** | https://code.claude.com/docs/en/sub-agents | 서브에이전트 설정 |
| **Plugins** | https://code.claude.com/docs/en/plugins | 플러그인 마켓플레이스 |
| **Permission Modes** | https://code.claude.com/docs/en/permission-modes | 권한 모드 설정 |
| **Settings** | https://code.claude.com/docs/en/settings | 설정 파일 계층 |
| **Context Window** | https://code.claude.com/docs/en/context-window | 컨텍스트 시각화 |
| **Features Overview** | https://code.claude.com/docs/en/features-overview | 기능 선택 가이드 |
| **Full Doc Index** | https://code.claude.com/docs/llms.txt | 전체 문서 인덱스 |

---

## CLAUDE.md 베스트 프랙티스 요약

### 크기·구조
- **200줄 이내** 유지 (초과 시 Claude가 지시를 무시하기 시작)
- 마크다운 헤더·불릿으로 구조화 (Claude도 사람처럼 구조를 스캔)
- 구체적·검증 가능한 지시 ("2-space 들여쓰기" ✅, "깔끔하게 포맷" ❌)
- 충돌하는 규칙 없도록 정기 리뷰

### 포함할 것
- Claude가 추측 못하는 Bash 커맨드
- 기본값과 다른 코드 스타일 규칙
- 테스트 지시·선호 러너
- 저장소 관습 (브랜치 네이밍, PR 컨벤션)
- 프로젝트 고유 아키텍처 결정
- 개발환경 특이사항 (환경변수 등)
- 흔한 함정·비명시적 동작

### 제외할 것
- Claude가 코드를 읽으면 알 수 있는 것
- 언어 표준 관습 (Claude가 이미 앎)
- 상세 API 문서 (링크로 대체)
- 자주 변경되는 정보
- 파일별 코드베이스 설명
- "깨끗한 코드를 작성하라" 같은 자명한 것

### 계층 구조
```
관리 정책 CLAUDE.md    → IT/DevOps가 배포, 전 사용자 적용
프로젝트 CLAUDE.md     → ./CLAUDE.md, 팀 공유 (git)
사용자 CLAUDE.md       → ~/.claude/CLAUDE.md, 개인 전역
로컬 CLAUDE.md         → ./CLAUDE.local.md, 개인 프로젝트 (.gitignore)
하위 디렉토리 CLAUDE.md → 온디맨드 로딩
.claude/rules/         → 주제별 분리, paths로 조건부 로딩
```

### @import 활용
```markdown
@README.md
@package.json
@docs/git-instructions.md
@~/.claude/my-project-instructions.md
```

---

## Hooks 베스트 프랙티스 요약

### 핵심 원칙
- CLAUDE.md = 권고 (advisory), Hooks = 보장 (deterministic)
- "예외 없이 매번 실행"해야 하면 Hook으로
- SessionStart 훅은 빠르게 유지

### 주요 이벤트
| 이벤트 | 용도 |
|--------|------|
| SessionStart | 컨텍스트 로딩, 환경 검증 |
| PreToolUse | 위험 명령 차단, 권한 제어 |
| PostToolUse | 린팅, 포매팅 자동 실행 |
| Stop | 완료 후 검증, 알림 |

### 설정 위치
- `~/.claude/settings.json` — 전역
- `.claude/settings.json` — 프로젝트 (git 공유)
- `.claude/settings.local.json` — 프로젝트 로컬
- 스킬/에이전트 frontmatter — 컴포넌트별

---

## Skills 베스트 프랙티스 요약

### CLAUDE.md vs Skills
- CLAUDE.md: 매 세션 로딩, 항상 적용되는 규칙
- Skills: 온디맨드 로딩, 특정 작업에만 적용
- 도메인 지식·워크플로우는 Skills로 분리

### 구조
```
.claude/skills/
├── api-conventions/
│   └── SKILL.md
├── fix-issue/
│   └── SKILL.md
└── deploy/
    └── SKILL.md
```

### disable-model-invocation
- 부작용이 있는 워크플로우 → `disable-model-invocation: true`
- 수동 호출만 허용

### model 선택 (스킬/에이전트 frontmatter)

CC v2.1.80+에서 스킬·에이전트 frontmatter에 `model:` 지정 가능.
전역 settings.json 기본값을 오버라이드한다.

```markdown
---
model: opus    # claude-opus-4-6
model: sonnet  # claude-sonnet-4-6  (기본값이 opus일 때 비용 절감)
model: haiku   # claude-haiku-4-5   (반복·단순 작업)
---
```

**판별 기준:**

| 특성 | 모델 | 이유 |
|------|------|------|
| 전략 판단 / 아키텍처 결정 | opus | 멀티스텝 추론 필요 |
| 보안 감사 / 취약점 분석 | opus | 미묘한 패턴 탐지 |
| 근본 원인 분석 / 5 Whys | opus | 인과 추론 깊이 |
| 연구·합성 / 교차 분석 | opus | 복수 소스 통합 |
| 코드 구현 / 기능 개발 | sonnet | 충분한 코딩 역량 |
| 반복 실행 루프 (ralph-loop) | sonnet | 수십 번 호출 → 비용 |
| QA 자동화 / 브라우저 테스트 | sonnet | 실행 중심 |
| 배포 / git / PR 워크플로 | sonnet | 절차적 작업 |
| 문서 작성 / 보고서 생성 | sonnet | 구조화된 출력 |
| 상태 토글 / 단순 체크 | haiku | 로직 없는 I/O |
| 알림 / 로그 기록 | haiku | 텍스트 포워딩 |

**셋업 모드 적용 규칙:**
- WHEN: 스킬이 전략적 판단·다단계 추론을 수행 THEN: `model: opus`
- WHEN: 스킬이 코드 생성·반복 실행·절차적 워크플로 THEN: `model: sonnet`
- WHEN: 스킬이 상태 읽기·체크·단순 출력 THEN: `model: haiku`
- WHEN: 전역 settings.json 기본값이 이미 opus THEN: sonnet/haiku만 명시 (opus는 기본이므로 생략 가능)
- NEVER: `model:` 없이 방치 — 기본값이 뭔지 모르는 채 비용 낭비

---

## Subagents 베스트 프랙티스 요약

### 핵심: 컨텍스트 보호
- 서브에이전트는 별도 컨텍스트에서 실행 → 메인 세션 오염 방지
- 조사·탐색은 서브에이전트로 위임
- 코드 리뷰도 서브에이전트가 효과적 (자기 코드 편향 없음)

### 구조
```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities
tools: Read, Grep, Glob, Bash
model: opus
---
```

---

## Permission & Sandbox 요약

| 모드 | 적합한 상황 |
|------|------------|
| Default | 처음 사용, 모든 것 확인 |
| Auto | 방향을 신뢰, 위험만 차단 |
| Allowlist | 특정 안전 커맨드만 허용 |
| Sandbox | OS 수준 격리, 자유롭게 작업 |

---

## 셋업 모드에서의 활용법

무한사고 셋업 모드는 위 베스트 프랙티스를 기반으로:

1. **CLAUDE.md 감사**: 기존 CLAUDE.md가 200줄 초과? 충돌 규칙? → 정리 제안
2. **계층 최적화**: 글로벌 vs 프로젝트 vs 로컬 분리가 적절한지 확인
3. **Skills 분리**: CLAUDE.md에 있어야 할 것 vs Skills로 옮길 것 판별
4. **Hooks 추천**: 프로젝트 특성에 맞는 필수 Hook 제안
5. **Rules 구조화**: .claude/rules/로 분리가 필요한 규칙 식별
6. **도구 버전 확인**: bkit/g-stack 현재 버전 확인 → 최신 기능 매핑

### 버전 업데이트 시 재핏팅
bkit이나 g-stack이 업데이트되면:
1. 위 공식 문서 링크에서 최신 변경사항 확인
2. 새로운 기능·변경된 패턴이 있으면 Project Fit의 "코딩 도구 커스텀" 섹션 업데이트
3. 새 훅 이벤트·스킬 패턴이 추가되었으면 하네스 설정 반영
4. 변경 사항을 CLAUDE.md의 누적 교훈에 기록

---

## Hooks 체크리스트 (셋업 시 확인)

| Hook | 역할 | 필수 여부 |
|------|------|----------|
| PreToolUse:Bash → global-careful.sh | 파괴적 명령 차단 | 필수 |
| PostToolUse:Write → typecheck.sh | tsc 자동 실행 | TS 프로젝트 필수 |
| PostToolUse:Write/Edit → security-scan.sh | .env 노출·시크릿 차단 | 필수 |
| SessionStart → start-servers.sh | 개발 서버 자동 기동 | 권장 |
| Stop → slack-notify.sh | 완료 알림 | 선택 |

## Plugins 체크리스트 (v2.5)

| Plugin | 역할 | 설치 |
|--------|------|------|
| bkit | PDCA 기반 개발 프로세스 | `plugin:bkit@bkit-marketplace` |
| usage-gate | 모델 사용량 실시간 추적 | `claude plugin add github:jung-wan-kim/usage-gate` |
| ralph-loop | 자율 반복 실행 루프 | `/plugin install ralph-loop@claude-plugins-official` |

## 모델 전략 빠른 참조 → `~/.claude/rules/model-strategy.md`

## 교훈 생명주기 (v2.5)

```
생성 → 축적(CLAUDE.md) → 패턴탐지(3회+) → 승격(rules/) → 강제화(hooks) → 졸업(archive)
                                                    ↑
                                        retrospective-engine이 제안
```
