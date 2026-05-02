# 페이즈 프롬프트 템플릿

> 메인 세션이 페이즈를 분할할 때 이 구조로 작성한다.
> 각 페이즈 파일은 **자기완결적(self-contained)** 이어야 한다.
> 메인 세션의 대화 히스토리에 의존하지 말 것.

---

## 페이즈 N: <한 줄 제목>

### 작업 의도 (Why)
이 페이즈가 왜 필요한가. 1~3줄.

### 작업 범위 (What)
- 변경할 파일: `path/to/file.ts`, `path/to/another.py`
- 추가할 파일: `path/to/new.tsx`
- 절대 건드리지 말 것: `path/to/sacred.ts`

### 참조해야 할 것 (Context)
- 스펙: `spec/feature.md` §3
- 직전 페이즈 변경분: docs.diff (자동 주입됨)
- 기존 패턴: `src/components/Existing.tsx` 와 동일하게

### 구현 지침 (How)
구체적 구현 단계 1~5개. 추정 금지, 실측 기반.

1. ...
2. ...
3. ...

### 완료 조건 (Done)
- [ ] 검증 가능한 기준 1
- [ ] 검증 가능한 기준 2
- [ ] typecheck 통과
- [ ] 관련 테스트 통과 (`npm test path/to/test`)

### 실패 조건 (Fail)
이 중 하나라도 해당되면 실패로 간주:
- ...
- ...

### 자가 검증
완료 직전 반드시 실행:
```bash
npm run typecheck
npm test path/to/test
```
