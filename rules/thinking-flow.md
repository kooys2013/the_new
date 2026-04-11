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

## 도구 선택

```
"뭘 만들지 정리"   → planning-generator → bkit PDCA Plan
"코드 작성"        → bkit PDCA Do
"전부 알아서 해"   → unbounded "한방에 개발"
"만든 거 검토"     → g-stack /review
"보안 괜찮은지"    → g-stack /cso
"왜 안 되지"       → problem-solver
"배포 전 검증"     → unbounded "한방에 검증"
"이번 주 회고"     → retrospective-engine → g-stack /retro
```
