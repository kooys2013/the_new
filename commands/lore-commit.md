---
description: 중요 결정 commit에 Why/Decision/Alternatives 3 trailer + Co-Authored-By 자동 부여 — git history에 결정 영속성 확보
---

# /lore-commit

> **목적**: 1년 후 `git log --grep "Decision:"`으로 결정 검색 가능한 commit 만들기.
> **원천**: autopus-adk lore git trailer 패턴 차용 (mempalace knowledge drawer는 별도 저장소 — 둘 다 보강).

## 자동화 우선 원칙 (사용자 선호 반영)

> **사용자는 hook 기반 자동 권고를 강하게 선호한다. 수동 슬래시 입력은 fallback.**

- **1차 (자동, 권장)**: `~/.claude/hooks/lore-commit-suggest.sh` (PostToolUse on Write/Edit) — 민감 파일(auth/rls/sql/migration/engine·strategy_config 등) 변경 감지 시 다음 commit에 `/lore-commit` 사용을 추천 메시지로 노출.
- **2차 (수동, 보조)**: 사용자가 직접 `/lore-commit "<제목>" --why="..." --decision="..." --alternatives="..."` 입력.
- **금지**: 일상 commit에 강제하지 말 것 (월 2~3회 자발 사용 기대). 자동 강제 hook 미설치.

## 사용법

```
/lore-commit "feat(canary): paper trading enable" \
  --why="Stage 2 GO 후 실측 갭 측정 필요" \
  --decision="BR=0.5%로 반쪽 카나리 시작" \
  --alternatives="BR=1% (full risk, 거부: 카나리 정책 위반) / BR=0% paper-only (거부: 실측 0)"
```

## 합성 흐름

1. 인자 파싱: 첫 위치 인자 = commit 제목. 나머지 `--why`/`--decision`/`--alternatives`.
2. 누락 검증: 3 trailer 중 하나라도 비어 있으면 사용자에게 보완 요청 (하드 블록 아님).
3. `git status --short` + `git diff --shortstat --cached`로 스테이징 확인. 비어 있으면 `git add` 안내.
4. HEREDOC으로 commit 메시지 본문 합성:

```bash
git commit -m "$(cat <<'EOF'
<제목>

Why: <--why 값>
Decision: <--decision 값>
Alternatives: <--alternatives 값>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

5. commit 후 `git log -1 --format=%B`로 trailer 3개 모두 출력 확인 → 사용자에게 결과 표시.

## 회수 (1년 후)

```bash
# 모든 결정 검색
git log --all --grep "^Decision:" --oneline

# 특정 영역 결정 회고
git log --all --grep "^Decision:" -- engine/ scripts/

# 특정 결정 + 대안 함께 보기
git log --grep "^Decision: BR=" --format="%h %s%n  Why: %b" | head -40
```

## 사용 비트리거

- 일상 버그 fix (`fix: typo`) — Co-Authored-By만으로 충분
- WIP commit / squash 예정 commit
- 자동 hook(PostToolUse)이 권고하지 않은 commit

## 참조

- `rules/coding-tools.md` g-stack 표 — `/lore-commit` 행
- `rules/mempalace-workflow.md` — knowledge drawer (병행 보강 저장소)
- `~/.claude/hooks/lore-commit-suggest.sh` — 자동 권고 hook
