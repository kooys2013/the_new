<!-- last-updated: 26/04/17 -->
<!-- archive-after: 26/10/17 (6개월 후 자동 archive 대상) -->
---
description: Anthropic 블로그 2026년 4월 핵심 5개 글 요약 — 단일 출처 참조용
paths:
  - "__on_demand_only__"
---

# Anthropic Blog — 2026년 4월 핵심 요약

> 이 파일이 단일 출처. 다른 rules/skills에서는 이 파일을 링크만 할 것.
> 반영 완료 파일 목록: `rules/advisor-strategy.md`, `rules/multi-agent-patterns.md`,
> `rules/model-strategy.md`, `rules/tool-routing.md`, `skills/unbounded-engine/SKILL.md`

---

## 1. Advisor Strategy
**URL**: https://claude.com/blog/the-advisor-strategy
**핵심**: Sonnet/Haiku executor + Opus advisor를 **단일 /v1/messages 호출** 안에서 결합.
- `anthropic-beta: advisor-tool-2026-03-01` 헤더 + `type: advisor_20260301` 도구
- SWE-bench Multilingual: Sonnet+Opus = Sonnet 대비 **+2.7pp, 비용 -11.9%**
- BrowseComp: Haiku+Opus = **41.2%** vs Haiku 단독 **19.7%** (2배+)
- Haiku+Opus 조합: Sonnet 대비 성능 -29%, 비용 **-85%**
- **반영**: `rules/advisor-strategy.md` + `rules/model-strategy.md §4.5`

---

## 2. Claude Opus 4.7 업데이트
**URL**: https://claude.com/blog (4월 업데이트 공지)
**핵심**: Opus 4.7 강점 재정의
- 확장된 추론 깊이 (아키텍처·보안·연구 합성 특화)
- 도구 호출 정확도 개선 (복잡한 tool-use 체인에서 더 안정적)
- 장문 컨텍스트 활용 능력 향상 (200k 컨텍스트 전체 활용)
- **반영**: `rules/model-strategy.md §1` 각주

---

## 3. Subagents 베스트 프랙티스
**URL**: https://claude.com/blog (4월 서브에이전트 가이드)
**핵심**: 에이전트 description 작성 원칙 + 위임 기준
- description은 "언제 쓰나" + "무엇을 하나" + "무엇을 하지 않나" 3요소
- 서브에이전트 prompt는 **self-contained** (대화 히스토리 의존 금지)
- 결과 검증: "에이전트가 했다고 *의도*한 것" ≠ "실제로 한 것" — diff 확인 필수
- **반영**: `rules/multi-agent-patterns.md` 각 패턴의 "언제 피하나" 섹션

---

## 4. Multi-agent Coordination Patterns
**URL**: https://claude.com/blog (4월 다중에이전트 조율 패턴)
**핵심**: 5가지 조율 패턴 — Orchestrator / Swarm / Pipeline / Review / Fan-out
- 각 패턴에 "언제 쓰나 / 언제 피하나" 명확 구분
- Fan-out: 같은 파일 동시 쓰기 race condition 위험
- Review 패턴 = Advisor의 다중 턴 버전
- **반영**: `rules/multi-agent-patterns.md` (전체)

---

## 5. Seeing like an Agent
**URL**: https://claude.com/blog (4월 에이전트 관찰 가능성 원칙)
**핵심**: 도구 출력은 **에이전트가 관찰해서 의사결정**할 수 있도록 설계
- 도구 출력 3원칙:
  1. **상태 가시성**: 현재 상태를 명확히 (✅/❌/⚠ 접두 포함)
  2. **다음 액션 힌트**: "→ 권장 다음 단계" 포함
  3. **에러 구체성**: "실패" X, "왜 실패했고 어떻게 고치나" O
- Hook 출력, statusline, 멘토 브리핑 모두 이 원칙 적용
- **반영**: `rules/tool-routing.md` (Seeing like an agent 섹션)

---

## 6월 이후 재동기화

- `hooks/weekly-fit-analyzer.sh` 주간 블로그 스캔이 신규 글 감지
- `skills/unbounded-engine/SKILL.md` Phase 2에서 최근 30일 글 1개+ 참조
- 새 핵심 글 등장 시 이 파일에 추가 + 반영 파일 목록 갱신
