# Meta-Harness — 자가발전 AI 개발 시스템

> 사고는 스킬이 하고, 코딩은 도구가 하며, 실수는 기록이 막는다.

## 핵심 흐름

```
메타질문 → 기획 → 문제해결 → 연구 → 자율반복 → 검증 → 회고
   ↑                                                    │
   └────────────── 자가발전 루프 ────────────────────────┘
          ↕
   [기억] MemPalace (실수축적·맥락검색·성장일지)
```

상세 스킬 매핑 → `rules/thinking-flow.md`
코딩 도구 가이드 → `rules/coding-tools.md`
**MemPalace 프로토콜 → `rules/mempalace-workflow.md`**

## 절대 규칙

- ALWAYS: 사고 결론 후 코딩 (생각 먼저, 코딩 나중)
- NEVER: 사고 스킬 중 코드 작성 금지
- WHEN: 플랜 모드 ExitPlanMode 직후 THEN: 계획 파일이 PRD/FS/IA/UF 구조가 아니면 planning-generator 프레임으로 재구조화 제안
- 스킬 퀵레퍼런스 → `rules/skill-quickref.md` (키워드→스킬 1페이지)
- 모델 전략 → `rules/model-strategy.md`
- 자동 트리거 → `rules/auto-triggers.md`
- 도구 라우팅 → `rules/tool-routing.md`

## 교훈 생명주기

```
생성→축적(여기)→3회반복→승격(rules/)→위반반복→강제화(hooks)→졸업(archive)
```

누적 교훈 → `rules/accumulated-lessons.md`

## 폴더 정책

| 용도 | 위치 |
|------|------|
| 대용량·일시적 | `_large_data/` (gitignore) |
| 보고서 | `_report/` (gitignore) |
| 소스 | 프로젝트 루트 |

## 준수 사항

- CLAUDE.md 50줄 이내 (초과 → rules/ 승격)
- 활성 MCP 3개 이하, 스킬 50개 이하
- Skills description만 상시 로드 (점진적 공개)
- CLI 도구(git, docker)는 MCP 대신 직접 사용
- 성공은 침묵, 실패만 소리 (Hook 원칙)
- **MemPalace palace: `~/.mempalace/` — 실수·맥락·성장일지 저장소**
