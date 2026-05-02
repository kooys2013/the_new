---
description: 파일 계층화 원칙 — CLAUDE.md·rules·skills 3층 구조로 컨텍스트 팽창 방지
paths:
  - "__on_demand_only__"
---

# File Layering 원칙 (파일 계층화)

> 공식 한도: CLAUDE.md ≤200줄/파일 (초과 → 준수율 저하).
> 하네스 정책: 전역 CLAUDE.md ≤50줄, 프로젝트 CLAUDE.md ≤100줄.
> 규칙: **항상 로드**는 최소화, **온디맨드**에 최대 위임.

---

## 1. 3층 구조

```
Layer 1 — 항상 로드 (컨텍스트 비용 높음)
  ~/.claude/CLAUDE.md          ≤50줄   전역 핵심 원칙만
  ~/.claude/rules/*.md         ≤200줄  전역 규칙 (모든 프로젝트)
  ./CLAUDE.md                  ≤100줄  프로젝트 공유 (팀)
  ./CLAUDE.local.md            ≤50줄   개인 전용 (gitignore)

Layer 2 — 경로 매칭 시만 로드 (중간)
  ./.claude/rules/X.md         paths: 프론트매터 필수
  ~/.claude/rules/X.md         paths: 프론트매터 필수

Layer 3 — 온디맨드만 (컨텍스트 비용 0)
  ~/.claude/skills/*/SKILL.md  스킬 호출 시에만 로드
  @path/to/file                명시 import 시에만 확장
```

---

## 2. 내용 → 위치 결정표

| 내용 유형 | 위치 | 이유 |
|----------|------|------|
| 모든 프로젝트에 항상 필요한 원칙 (5줄 이내) | `~/.claude/CLAUDE.md` | 전역 최상위 |
| 전역 규칙 (항상 로드, 단일 주제) | `~/.claude/rules/주제.md` | 파일 분리 |
| 특정 파일 타입에만 적용되는 규칙 | `rules/X.md` + `paths:` 프론트매터 | 경로 매칭 |
| 절차·워크플로우 (다단계, 온디맨드) | `~/.claude/skills/X/SKILL.md` | 필요 시만 로드 |
| 프로젝트 팀 공유 규칙 | `./CLAUDE.md` 또는 `./.claude/rules/` | 버전 관리 |
| 개인 프로젝트 전용 메모 | `./CLAUDE.local.md` (gitignore) | 개인만 |
| 대용량 참조 문서 | `@relative/path` import | CLAUDE.md 외부화 |
| 누적 교훈 | `rules/accumulated-lessons.md` | Tactical DNA |

---

## 3. 크기 초과 시 처리 규칙

### `~/.claude/CLAUDE.md` > 50줄
→ **즉시 이동**: 초과 내용을 `rules/` 파일로 분리 + 포인터 1줄만 남김

### `./CLAUDE.md` > 100줄
→ **분할 검토**: 주제별로 `.claude/rules/X.md`로 분리

### `./CLAUDE.md` > 200줄 (공식 한도)
→ **반드시 분할**: 준수율 저하 보장. 절차·가이드는 skills로 이동

### `rules/*.md` > 200줄
→ **2파일 분할**: `rules/주제-core.md` + `rules/주제-detail.md`

### `skills/*/SKILL.md` > 500줄
→ **references/ 분리**: 상세 내용을 `skills/X/references/` 서브폴더로 이동

---

## 4. 프로젝트 신규 진입 시 체크리스트

```
1. ./CLAUDE.md 존재?
   - 없음 → /init 실행 (자동 생성)
   - 있음 → 줄 수 확인: 100줄 이하면 OK, 초과면 .claude/rules/ 분할
   
2. 전역 규칙이 필요한가?
   - 이 프로젝트에만 필요 → ./CLAUDE.md or ./.claude/rules/
   - 모든 프로젝트 필요 → ~/.claude/rules/

3. 절차가 필요한가?
   - 5줄 이내 → CLAUDE.md inline
   - 5줄 초과 → skills/ 또는 @import 외부 파일

4. @import 활용:
   @./docs/architecture.md      # 큰 참조 문서
   @./.claude/context/stack.md  # 스택별 컨텍스트
```

---

## 5. ALWAYS / NEVER

- ALWAYS: 새 규칙 추가 전 "항상 로드가 필요한가?" 자문 → No면 skills/ 또는 @import
- ALWAYS: **신규 rules paths 기본값 = `__on_demand_only__`**. `**/*` 또는 광범위 패턴은 Core DNA(user-eye/harsh-critic/service-completion-checklist/skill-quickref/thinking-flow/accumulated-lessons 6종)만 허용 [since:26/04/28]
- ALWAYS: CLAUDE.md 수정 후 줄 수 확인 (`wc -l CLAUDE.md`)
- ALWAYS: 프로젝트 CLAUDE.md에 전역 규칙 복붙 금지 → `~/.claude/rules/` 참조
- NEVER: CLAUDE.md에 절차·가이드·예시 코드를 통째로 넣기 → skills로 이동
- NEVER: 같은 내용을 전역·프로젝트·로컬 3곳에 중복 작성
- NEVER: rules/*.md 파일에 paths: 없이 스택별 규칙 작성 → false-positive 로드
- NEVER: rules 신규 작성 시 paths를 `**/*` 또는 `**/*.{py,ts,...}` 광범위 패턴으로 설정 → 컨텍스트 폭식 유발 [since:26/04/28]

---

## 6. @import 패턴

```markdown
# 프로젝트 CLAUDE.md 예시 (≤100줄 유지)
## Stack
@./.claude/context/stack.md      # 스택별 설정 (경량)

## Architecture  
@./docs/ARCHITECTURE.md          # 아키텍처 (대용량도 OK — 온디맨드)

## Conventions
- Use 2-space indent
- Run `bun test` before commit
```

---

## 관련 파일

- 공식 문서: https://code.claude.com/docs/en/memory
- `rules/STRUCTURE.md` — Core / Tactical / Memory / Session DNA 4티어
- `rules/accumulated-lessons.md` — 교훈 승격 저장소
- `rules/asset-lifecycle.md` — active → dormant → archived 생명주기
