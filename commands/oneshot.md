---
description: '한방 모드 명시 진입점 — unbounded-engine의 한방에 개발/검증/조언/셋업 모드를 슬래시 커맨드로 발동 (autopus /auto dev 패턴 차용)'
argument-hint: '[dev|verify|advise|setup] "기능설명"'
allowed-tools: ['Skill', 'Read', 'Glob', 'Grep']
---

# /oneshot — 한방 모드 명시 진입점

## 자동화 우선 원칙 (중요)

> **사용자는 hook 기반 자동 발동을 강하게 선호한다. 수동 슬래시 입력은 fallback.**

- **1차 (자동, 권장)**: `~/.claude/hooks/oneshot-trigger.sh` (UserPromptSubmit hook)가
  자연어 키워드("한방에 개발", "한방에 검증", "조언", "갈림길" 등)를 감지하여
  자동으로 본 커맨드와 동등한 흐름으로 진입. 사용자는 평소처럼 자연어로 말하면 됨.
- **2차 (수동, 보조)**: 사용자가 명시적으로 `/oneshot <서브커맨드> "..."` 입력 시 본 커맨드 직접 실행.
- **금지**: 자동 발동 가능한 흐름을 "/oneshot 입력해주세요"로 사용자에게 떠넘기기 (user-eye H1 떠넘기기 위반).

자동 발동 조건/매트릭스는 hook 스크립트 `~/.claude/hooks/oneshot-trigger.sh` 본문 참조.

## 진입 메시지 (반드시 출력)

```
한방 모드 진입 — Phase A부터 시작합니다 (사고→구현→검증→회고).
중단하려면 Esc.
```

## 서브커맨드 라우팅

사용자 인자 `$ARGUMENTS`의 첫 토큰이 서브커맨드:

| 서브커맨드 | 호출 대상 | 트리거 키워드 (Skill에 전달) |
|-----------|----------|------------------------------|
| `dev`     | unbounded-engine | "한방에 개발: {나머지 인자}" |
| `verify`  | unbounded-engine | "한방에 검증: {나머지 인자}" |
| `advise`  | unbounded-engine | "무한조언: {나머지 인자}" |
| `setup`   | unbounded-engine | "하네스 셋업: {나머지 인자}" |

서브커맨드 누락 시 → 사용 예시 출력 후 종료:
```
사용법: /oneshot dev "기능 설명"
       /oneshot verify "검증 대상"
       /oneshot advise "고민 주제"
       /oneshot setup "프로젝트 경로 또는 'current'"
```

## 실행

`Skill` 도구로 `unbounded-engine` 호출. args에 트리거 키워드 + 사용자 인자를 그대로 전달 — unbounded-engine SKILL.md frontmatter description의 모드별 키워드 매칭이 발동.

## 모드별 사전 조건 (Skill 호출 전 1회 점검)

- `dev` — PRD/기능 명세 1줄 이상 있는가? 없으면 사용자에게 1줄 받고 진행
- `verify` — 검증 대상(파일/PR/branch)이 명확한가?
- `advise` — 비실행. 사용자 결정 보조 — 5인 자문위원회 1~2줄 출력 후 종료
- `setup` — 현재 디렉토리에 CLAUDE.md 존재 여부 확인 후 진입

## 자가 검증 (커맨드 종료 전)

- [ ] 진입 메시지 출력했는가?
- [ ] 서브커맨드 라우팅 표대로 정확한 키워드를 Skill에 전달했는가?
- [ ] 모드 도중 사용자 Esc 신호 시 즉시 중단하는가?

## 참조

- 한방에 개발 모드 정의: `~/.claude/skills/unbounded-engine/SKILL.md` L1056~L1102
- 한방에 검증 모드 정의: 같은 파일 L1105~L1141
- 무한조언 모드 정의: 같은 파일 frontmatter L80~L84
- 셋업 모드 정의: 같은 파일 frontmatter L35~L45
