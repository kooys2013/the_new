---
paths:
  - "**/*"
---
# 코딩 도구 가이드

## g-stack (검증 도구)

| 언제 | 커맨드 | 취지 |
|------|--------|------|
| 코드 리뷰 | /review | 프로덕션 버그 탐지 |
| 보안 점검 | /cso | OWASP+STRIDE |
| QA 테스트 | /qa | 브라우저 기반 |
| 아키텍처 | /plan-eng-review | 엔지니어링 리뷰 |
| 교차검증 (diff 리뷰) | /codex review | GPT 독립 리뷰 Pass/Fail |
| 교차검증 (설계 도전) | /codex adversarial-review | 접근법 자체를 챌린지 |
| 작업 위임 (교착) | /codex:rescue | 디버깅/구현 통째 GPT 위임 |
| 배포 | /ship | PR + 배포 |
| 회고 | /retro | 주간 리뷰 |
| UI 검증 | /visual-proof | 스크린샷 보고서 |

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
