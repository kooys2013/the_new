# Next.js 프로젝트 CLAUDE.md 보일러플레이트

> unbounded-engine 셋업 모드에서 Next.js 프로젝트 감지 시 자동 참조

```markdown
# [프로젝트명] — Next.js

## 스택
- Next.js {버전} (App Router / Pages Router)
- TypeScript
- {상태관리}: Zustand / Redux / Context
- {스타일}: Tailwind CSS / CSS Modules / styled-components
- {DB}: Supabase / Prisma / Drizzle

## 빌드·실행
- `pnpm dev` — 개발 서버 (포트: {3000})
- `pnpm build` — 프로덕션 빌드
- `pnpm lint` — ESLint
- `pnpm test` — Vitest / Jest

## 아키텍처
- App Router: `app/` (layout.tsx, page.tsx, loading.tsx, error.tsx)
- 서버 컴포넌트 기본, 클라이언트 필요 시 'use client' 명시
- API Routes: `app/api/` (Route Handlers)
- 미들웨어: `middleware.ts` (인증·리다이렉트)

## 도메인 규칙
- ALWAYS: 서버 컴포넌트 우선 (데이터 페칭은 서버에서)
- ALWAYS: Image → next/image, Link → next/link
- NEVER: useEffect로 데이터 페칭 금지 (서버 컴포넌트 또는 SWR/React Query)
- NEVER: 클라이언트 컴포넌트에서 직접 DB 접근 금지
- WHEN: 동적 라우팅 THEN: generateStaticParams 고려
- WHEN: 폼 처리 THEN: Server Actions 우선 (useFormState + useFormStatus)
- WHEN: 환경변수 THEN: NEXT_PUBLIC_ 접두사 구분 엄격

## 코딩 도구
- bkit PDCA + g-stack /review + /qa + /cso

## 누적 교훈
<!-- retrospective-engine 자동 추가 -->
```
