---
paths:
  - "__on_demand_only__"
---
# 코딩 도구 가이드

## g-stack (검증 도구)

| 언제 | 커맨드 | 취지 |
|------|--------|------|
| 코드 리뷰 | /review | 프로덕션 버그 탐지 |
| 보안 점검 | /cso | OWASP+STRIDE |
| QA 테스트 | /qa | 브라우저 기반 |
| 아키텍처 | /plan-eng-review | 엔지니어링 리뷰 |
| 배포 | /ship | PR + 배포 |
| 회고 | /retro | 주간 리뷰 |
| UI 검증 | /visual-proof | 스크린샷 보고서 |
| 중요 결정 커밋 | /lore-commit | Why/Decision/Alternatives 3 trailer 자동 (PostToolUse hook이 민감 파일 변경 감지 시 권고) |

## Codex (공식 플러그인 — openai/codex-plugin-cc)

> Claude 결과물을 GPT 관점에서 교차검증 + 교착 시 병렬 위임.
> 설치: `/plugin install codex@openai-codex` → 인증: `!codex login`
> 설정: `.codex/config.toml` (프로젝트별 모델/effort)

| 언제 | 커맨드 | 취지 |
|------|--------|------|
| PR 전 코드 리뷰 | `/codex:review` | GPT 독립 리뷰 (read-only) |
| 브랜치 전체 리뷰 | `/codex:review` (--base main) | main 대비 전체 diff |
| 설계 도전 | `/codex:adversarial-review` | 방향·설계·가정 자체를 챌린지 |
| 교착 탈출 | `/codex:rescue [작업 설명]` | GPT에 작업 위임 |
| 이전 rescue 이어하기 | `/codex:rescue --resume` | 컨텍스트 유지 |
| 상태 확인 | `/codex:setup` | 설치·인증·버전 확인 |

### Codex 사용 규칙
- ALWAYS: PR 전 `/codex:review` (g-stack /review와 별도 교차검증)
- ALWAYS: 백테스트 엔진(engine/*.py) 수정 완료 시 `/codex:review` — e2e 파이프라인 오염 탐지
- ALWAYS: 신규 백테스트 스크립트(scripts/run_*.py) 완성 시 `/codex:review` — lookahead/KS 간섭 점검
- ALWAYS: 포트폴리오 시뮬레이터·레버리지 계산 변경 시 `/codex:review` — 복리 모델 오류 탐지
- WHEN: 백테스트 결과 해석 중 수치 의심 THEN: `/codex:adversarial-review` — 계산 로직 교차검증
- WHEN: 인수인계서(handover) 작성 전 THEN: `/codex:review` — 논리 일관성 확인
- WHEN: problem-solver 2회 실패 THEN: `/codex:rescue` 위임
- WHEN: 아키텍처 결정 THEN: `/codex:adversarial-review`
- NEVER: rescue 결과를 검증 없이 적용 — 반드시 Claude가 diff 확인

## bkit (PDCA 도구)

| 언제 | 기능 |
|------|------|
| 체계적 개발 | PDCA Plan→Design→Do→Check |
| 갭 분석 | gap-detector |
| 반복 수정 | Check-Act 루프 (5회, 90%) |
| 코드 분석 | code-analyzer |

## Pretext (UI 텍스트 레이아웃)

| 언제 | 적용 |
|------|------|
| HTML/UI 구현 | 텍스트 레이아웃은 반드시 Pretext |
| 다이나믹 텍스트 | prepare() + layout() 패턴 |
| Rich 텍스트 | prepareRichInline() |

- vendor: `~/.claude/skills/gstack/design-html/vendor/pretext.js` (v0.0.5)
- fallback: `https://esm.sh/@chenglou/pretext`
- NEVER: `system-ui` 폰트 사용 금지 (macOS 정확도 문제)
- NEVER: DOM offsetHeight/getBoundingClientRect로 텍스트 높이 측정 금지

## 플러그인 업데이트 (harness fit 시)

```bash
# gstack 업데이트
~/.claude/skills/gstack-upgrade

# bkit 업데이트  
claude plugin update bkit

# pretext vendor 재빌드
cd ~/.claude/skills/gstack && npm install @chenglou/pretext@latest && \
npx esbuild node_modules/@chenglou/pretext/dist/layout.js --bundle --format=esm --minify --outfile=design-html/vendor/pretext.js
```

## 규칙
- ALWAYS: PR 전 /review + /cso
- ALWAYS: HTML UI 생성 시 Pretext 사용 (design-html 스킬)
- WHEN: 핵심 로직 변경 THEN: /codex 추가
- WHEN: 신규 모듈 50줄+ THEN: bkit PDCA 고려
- WHEN: 스프린트 시작/harness fit THEN: 플러그인 업데이트 확인
- NEVER: bkit과 g-stack 같은 파일 동시 사용 금지
