---
name: research-pipeline
description: |
  (MASTER) 리서치 파이프라인 — 반드시 사용: 조사해줘, 리서치, 찾아줘, 선행연구, 문헌고찰, 시장 조사, 사례 찾아줘, 논문, 근거 있어, research, find evidence, investigate. For any research or investigation task. Do NOT use for creating documents or verifying claims.

  입력: 자연어 질문 / PDF 업로드 / URL / 시드 논문(DOI·제목)
  출력: 근거 테이블 / 갭 맵 / 연구 브리프 / PRISMA 플로우 다이어그램

  아래 키워드 중 하나라도 포함된 요청에서 반드시 이 스킬을 사용하라:
  "조사해줘", "리서치", "연구", "선행연구", "논문 찾아줘", "근거", "에비던스",
  "문헌고찰", "체계적 고찰", "systematic review", "literature review",
  "학술 검색", "논문 검색", "evidence", "research", "investigate",
  "사례 조사", "동향 분석", "기술 조사", "시장 조사", "벤치마크 조사",
  "어떤 연구가 있어", "뭐가 알려져 있어", "선례 있어", "근거 찾아줘",
  "깊이 파봐", "deep dive", "심층 분석", "find everything about",
  "법규 검토", "규정 확인", "표준 조사", "KOSHA", "PRISMA"

  사용자가 PDF나 논문 URL을 주면서 "분석해줘" "정리해줘"라고 해도 이 스킬을 적용하라.

  ※ 기획이 필요하면 planning-generator, 문제해결이 필요하면 problem-solver와 연동.
  ※ 연구 결과의 검증이 필요하면 verification-pipeline과 연동.
  ※ 이 스킬은 4형제 파이프라인의 두 번째: 기획 → [연구] → 문제해결 → 검증.
model: opus
---

# 연구 파이프라인 (research-pipeline)

> "주장의 가치는 그 뒤에 있는 근거의 질로 결정된다. 
>  검증되지 않은 지식은 추측일 뿐이다."
> — PRISMA + Harness 연구 철학

---

## 4형제 파이프라인에서의 위치

```
기획(planning)          연구(research)          문제해결(problem-solver)   검증(verification)
──────────────         ─────────────          ──────────────────       ──────────────────
미래를 설계한다        근거를 수집한다         문제를 해결한다           품질을 보증한다
PRD → FS → IA         Search → Screen →      Problem → RCA →          Pre/In/Post-flight
                      Extract → Synthesize    Solution → Action        → Go/No-Go Gate
"무엇을 만들 것인가"  "무엇이 알려져 있는가"  "무엇이 문제인가"        "정말 맞는가"
```

**연동 패턴:**
- 기획 중 기술적 근거 필요 → `research-pipeline`으로 선행연구 수집
- 연구 결과에서 문제 발견 → `problem-solver`로 원인 분석
- 문제 해결 시 유사 사례 조사 → `research-pipeline`으로 벤치마크
- 연구 결과 품질 확인 → `verification-pipeline`으로 교차 검증
- 대형 프로젝트: 기획 → 연구 → 문제해결 → 검증 순차 진행

---

## 핵심 원칙 (반드시 내면화하라)

| 원칙 | 설명 |
|------|------|
| **근거 우선(Evidence First)** | "검색하지 않은 것은 모른다." 모든 주장은 출처 기반이다 |
| **다중 소스 교차(Triangulation)** | 최소 3개 독립 소스가 일치해야 "높은 확신" |
| **체계적 편향 제거** | 검색어·DB 편향을 인식하고, 포함/배제 기준을 사전 정의 |
| **투명한 추적(Traceability)** | 모든 주장 → 출처 → 원문 문장까지 역추적 가능해야 한다 |
| **적응적 깊이** | 일상 질문은 5분 래피드 리뷰, 규제 근거는 풀 PRISMA |
| **갭 명시** | "찾지 못한 것"도 연구 결과다. 빈 영역을 명확히 보고한다 |
| **분석 제한** | 무한 검색 금지. 3라운드 스노우볼링 후 포화 미달 시 현재 결과로 보고 |

---

## Phase 0: 연구 유형 분류 (Gate & Classify)

요청을 받으면 **반드시 먼저** 연구 유형과 깊이를 판별하라.

### 연구 유형 분류표

| 유형 | 트리거 상황 | 주요 방법 | 산출물 |
|------|------------|----------|--------|
| **A. 래피드 리뷰** | 일상 질문, 간단한 사실 확인, 빠른 답 | 웹서치 + 상위 10건 스크리닝 | 1페이지 리서치 브리프 |
| **B. 주제 탐색** | 동향 분석, 기술 비교, 시장 조사 | 다중 DB 검색 + 테마별 분류 | 주제별 근거 테이블 + 갭 맵 |
| **C. 체계적 고찰** | 규제 근거, 학술 연구, 의사결정 지원 | 풀 PRISMA 7단계 | 근거 테이블 + PRISMA 플로우 + 합성 보고서 |
| **D. PDF/논문 분석** | 업로드된 PDF, URL, DOI 제공 | 메타데이터 추출 + 구조화 + 인용 체이닝 | 논문 요약 카드 + 관련 연구 맵 |
| **E. 법규/표준 조사** | KOSHA, 법령, ISO, 고시 확인 | 법령 DB + 행정규칙 검색 | 법규 적용 매트릭스 + 조문 요약 |

### 깊이 결정 (리고르 레벨)

| 깊이 | 기준 | 소요시간 | 소스 수 |
|------|------|---------|---------|
| **L0 — 즉답** | 단순 사실 확인 | <1분 | 1~2 |
| **L1 — 래피드** | 일상 조사, 참고용 | 5~10분 | 5~10 |
| **L2 — 표준** | 업무 의사결정 근거 | 15~30분 | 10~30 |
| **L3 — 심층** | 규제 대응, 학술 수준 | 30분~1시간+ | 30~100+ |

**즉시 시작 조건:** 질문이 명확하면 유형·깊이 판별 후 바로 Phase 1 진행.
**질문 필요 조건:** 유형이 애매하면 아래 중 최대 3개만 질문:
```
1. 🎯 이 조사의 목적은? (보고서용 / 의사결정용 / 학습용)
2. 📊 어느 정도 깊이가 필요한가요? (빠른 답 / 상세 분석 / 체계적 고찰)
3. 🌐 특정 분야나 지역 제한이 있나요? (한국만 / 글로벌 / 특정 산업)
```

---

## Phase 1: 연구 질문 구조화 (PICO/SPIDER 분해)

### 프레임워크 자동 선택

| 질문 유형 | 프레임워크 | 요소 |
|-----------|-----------|------|
| 개입/효과 질문 | **PICO** | Population, Intervention, Comparison, Outcome |
| 정성적 질문 | **SPIDER** | Sample, Phenomenon of Interest, Design, Evaluation, Research type |
| 노출/위험 질문 | **PEO** | Population, Exposure, Outcome |
| 공학/설비 질문 | **PICO 변형** | System, Technology/Method, Alternative, Performance Metric |

### FINER 품질 게이트 (7/10 이상이면 진행)

| 기준 | 0점 | 1점 | 2점 |
|------|-----|-----|-----|
| **F**easible (실현가능) | 데이터 접근 불가 | 부분적 접근 | 충분한 데이터 존재 |
| **I**nteresting (흥미/필요) | 누구도 관심 없음 | 일부 관련자에게 유용 | 핵심 의사결정에 직결 |
| **N**ovel (새로움) | 이미 충분한 답이 존재 | 부분적으로 미탐색 | 명확한 지식 갭 존재 |
| **E**thical (윤리적) | 윤리적 문제 있음 | 주의 필요 | 문제 없음 |
| **R**elevant (관련성) | 사용자 맥락과 무관 | 간접적 관련 | 직접적 관련 |

**산출물:** 구조화된 연구 질문 + 3~5개 검색 쿼리 변형 + 포함/배제 기준

---

## Phase 2: 다중 소스 검색 (PRISMA Identification)

### 소스 티어 맵 (도메인별 자동 선택)

| 티어 | 소스 | API/접근 방식 | 커버리지 |
|------|------|-------------|---------|
| **T1 글로벌 학술** | Semantic Scholar | REST API (무료, 214M+편) | 전 분야 |
| **T1 글로벌 학술** | OpenAlex | REST API (무료, 250M+편) | 전 분야 + 인용 그래프 |
| **T2 의료/바이오** | PubMed E-utilities | REST API (무료) | 의학·생명과학 |
| **T2 공학/CS** | arXiv | REST API (무료) | 물리·CS·수학 |
| **T3 한국 학술** | KCI (한국학술지인용색인) | data.go.kr API | 한국 학술지 |
| **T3 한국 학술** | RISS | riss.kr API | 한국 학위논문·학술지 |
| **T3 한국 학술** | DBpia | api.dbpia.co.kr | 한국 학회·저널 |
| **T4 법규/안전** | 국가법령정보센터 | law.go.kr Open API | 한국 법령·행정규칙 |
| **T4 법규/안전** | KOSHA 재해사례 | data.go.kr API | 산업재해 사례 |
| **T5 일반** | Claude 웹서치 | launch_extended_search_task | 웹 전체 |
| **T5 일반** | PDF 업로드 분석 | pdf-reading 스킬 연동 | 사용자 제공 문서 |

### 도메인별 소스 자동 배합

| 도메인 | 1순위 | 2순위 | 3순위 |
|--------|-------|-------|-------|
| **산업안전/환경** (KORENO) | KOSHA + 법령정보센터 | KCI/RISS | Semantic Scholar |
| **소프트웨어/개발** (GO프로젝트) | arXiv + GitHub | Semantic Scholar | OpenAlex |
| **트레이딩/금융** (MGTG) | Semantic Scholar + 웹서치 | OpenAlex | arXiv (quant-ph) |
| **사이드프로젝트** (옥타곤IQ 등) | 웹서치 | Semantic Scholar | 한국 DB |
| **일상 조사** | 웹서치 | 적절한 전문 DB | — |

### 개발 문서 소스 우선순위 (v2.5)

라이브러리·프레임워크·API 문서 조사 시 아래 순서를 따른다:

| 등급 | 소스 | 용도 | 신뢰도 |
|------|------|------|--------|
| **A** | Context7 MCP | 최신 공식 문서 (버전별 정확) | 최고 |
| **B** | 공식 GitHub 리포 | README, CHANGELOG, 이슈 | 높음 |
| **B-C** | 기술 블로그·Stack Overflow | 실전 해결책, 워크어라운드 | 중간 |
| **C** | WebSearch | 최신 정보, 커뮤니티 의견 | 검증 필요 |
| **D** | Claude 내부 지식 | 기본 개념, 일반 패턴 | 버전 편차 주의 |

- ALWAYS: 라이브러리 API 사용 시 Context7 MCP로 최신 문서 확인 후 코드 작성
- NEVER: Context7 없이 마이너 버전 이상 라이브러리 API를 기억에 의존
- WHEN: Context7 결과 불충분 THEN: GitHub 리포 직접 확인 → WebSearch 보완

### 검색 실행 규칙

1. **최소 2개 소스** 병렬 검색 (Fan-out 패턴)
2. **중복 제거**: DOI/제목 기준 자동 dedup
3. **검색 쿼리 기록**: 어떤 소스에 어떤 쿼리를 넣었는지 투명하게 기록
4. **소스별 히트 수 기록**: PRISMA 플로우 다이어그램용

---

## Phase 3: 스크리닝 (PRISMA Screening)

### 2단계 스크리닝

**1차 — 제목/초록 스크리닝:**
- Phase 1에서 정의한 포함/배제 기준 적용
- 각 소스에 Yes/No/Maybe 태깅
- Maybe는 2차로 넘김

**2차 — 본문 스크리닝 (L2 이상):**
- Maybe 및 경계선 소스의 본문 확인
- 최종 포함/배제 결정 + 사유 기록

### 스크리닝 결과 포맷

```
PRISMA 플로우:
  검색 결과: {T1}건 + {T2}건 + {T3}건 = 총 {N}건
  중복 제거 후: {N-dup}건
  1차 스크리닝 배제: {N-1st}건 (사유별 분류)
  2차 스크리닝 배제: {N-2nd}건 (사유별 분류)
  최종 포함: {N-final}건
```

---

## Phase 4: 인용 체이닝 (Wohlin 스노우볼링)

**L2 이상에서만 실행.** Phase 3 포함 논문을 시드로 사용.

### 스노우볼링 절차

1. **후방 체이닝(Backward):** 포함된 논문의 참고문헌 검토
   - 제목 → 학술지 → 인용 맥락 → 초록 → 본문 순 필터링
2. **전방 체이닝(Forward):** 포함된 논문을 인용한 논문 검색
   - Semantic Scholar Citations API 또는 OpenAlex `filter=cites:{id}` 사용
3. **유사성 확장:** Semantic Scholar Recommendations API
4. **반복 + 포화 판정:**
   - 라운드당 신규 논문 수 추적 → 감소 추세면 포화 접근
   - **3라운드까지 반복**, 포화 미달 시 현재 결과로 진행 + 갭 명시
   - 감소하지 않으면 → 누락된 클러스터 의심 → 동의어/대체 키워드로 재검색

---

## Phase 5: 데이터 추출 (Evidence Table)

### 표준 근거 테이블 스키마

| 열 | 설명 | 필수 |
|----|------|------|
| 저자/연도 | 저자명, 발행연도 | ✅ |
| 제목 | 논문/자료 제목 | ✅ |
| 연구 설계 | RCT, 관찰연구, 사례연구 등 | ✅ |
| 근거 등급 | A~E (Phase 6에서 판정) | ✅ |
| 대상/표본 | 인구, 표본 크기(N) | ✅ |
| 핵심 방법 | 사용된 방법론/기술 | ✅ |
| 주요 결과 | 핵심 발견 + 통계적 유의성 | ✅ |
| 한계점 | 저자가 밝힌 한계 | ✅ |
| 관련성 | 연구 질문과의 직접 연결 | ⚪ L2+ |
| 출처 링크 | DOI, URL | ✅ |

### 도메인별 추가 열

| 도메인 | 추가 열 |
|--------|---------|
| 산업안전 | 재해유형, 적용법규, 시정조치 |
| 트레이딩 | 수익률, 샤프비율, 백테스트 기간, IS/OOS 구분 |
| 소프트웨어 | 기술스택, 벤치마크 결과, 재현가능성 |
| 법규 | 법령명, 조항번호, 시행일, 소관부처 |

---

## Phase 6: 근거 등급화 (GRADE 적응형)

### 범용 근거 등급

| 등급 | 정의 | 시작점 | 예시 |
|------|------|--------|------|
| **A (높음)** | 체계적 고찰 / 메타분석 / 다중 RCT | — | Cochrane 리뷰, 대규모 메타분석 |
| **B (중간높음)** | 동료심사 1차 연구 | RCT→A, 관찰→C에서 조정 | 저명 학술지 논문 |
| **C (중간)** | 관찰연구 / 전문가 합의 | 관찰연구 기본 | 코호트연구, 전문가 패널 |
| **D (낮음)** | 비동료심사 / 회색문헌 | — | 기술 블로그, 백서, 프리프린트 |
| **E (매우낮음)** | 전문가 의견, 일화, 미확인 AI 생성 | — | 개인 경험, 검증 안 된 정보 |

### GRADE 조정 요인

**하향 요인 (−1 또는 −2):**
- 비뚤림 위험 (Risk of bias)
- 비일관성 (Inconsistency across studies)
- 비직접성 (Indirectness to research question)
- 비정밀성 (Imprecision — wide confidence intervals)
- 출판 편향 (Publication bias)

**상향 요인 (+1):**
- 큰 효과 크기 (Large effect size)
- 용량-반응 관계 (Dose-response gradient)
- 반대 방향 교란 (Confounders would reduce effect)

---

## Phase 7: 합성 및 보고 (Synthesis)

### 출력 형식 (유형별 자동 선택)

| 유형 | 출력 형식 |
|------|----------|
| A (래피드) | **리서치 브리프**: 핵심 메시지 3~5개 + 근거 요약 + 출처 |
| B (주제 탐색) | **근거 테이블** + **갭 맵** + 주제별 내러티브 합성 |
| C (체계적 고찰) | **풀 보고서**: 서론·방법·결과·논의 (IMRaD) + PRISMA 플로우 + 근거 테이블 |
| D (PDF 분석) | **논문 요약 카드** + 관련 연구 맵 (인용 기반) |
| E (법규 조사) | **법규 적용 매트릭스** + 조문 요약 + 시행일/소관부처 |

### 합성 보고서 필수 섹션

```
1. Executive Summary (핵심 메시지 3~5개)
2. 연구 질문 & PICO 분해
3. 검색 전략 & PRISMA 플로우 (투명성)
4. 근거 테이블 (구조화된 데이터)
5. 주제별 합성 (수렴점 + 발산점 + 불확실 영역)
6. 근거 등급 요약 (A~E 분포)
7. 갭 분석 (연구되지 않은 영역 명시)
8. 한계점 (이 리뷰 자체의 한계)
9. 시사점 & 다음 단계 (action-oriented)
10. 참고문헌 (DOI 포함)
```

### 갭 맵 포맷

```
         결과1    결과2    결과3
방법A  [ ●●● ]  [ ●○ ]  [ — ]
방법B  [ ●● ]   [ — ]   [ — ]
방법C  [ ● ]    [ ● ]   [ ●● ]

● = 근거 1건 (등급 표시)
— = 근거 없음 (연구 갭)
```

---

## Phase 8: 트렌드 스캔 모드 (Trend Harvester)

> 내부 학습만으로는 기술 생태계 변화에 뒤처진다.
> 외부 신호를 주기적으로 주입하여 DNA가 현실과 동기화되도록 한다.

### 트리거
- 세션 시작 시 "하네스 최신화", "셋업", "트렌드 스캔"
- auto-triggers.md의 주간 트리거
- unbounded-engine 셋업 모드 Step 1에서 자동 호출

### 스캔 소스 (프로젝트 스택별)

| 도메인 | 소스 | 우선순위 |
|--------|------|---------|
| Claude Code | https://code.claude.com/docs/ko/changelog (한국어 릴리스노트) + Anthropic 블로그 | A |
| Next.js/React | Context7 MCP + GitHub Releases | A |
| Supabase | Context7 MCP + supabase.com/blog | A |
| Python 생태계 | PyPI 트렌드 + GitHub trending | B |
| 보안 | GitHub Advisory DB + OWASP 업데이트 | A |
| 트레이딩 | Binance API changelog | B |
| Agent 방법론 | github.com/obra/superpowers (skill 업데이트 감지, 통합은 DNA 흡수 방식) | B |
| Agent 방법론 | github.com/Yeachan-Heo/oh-my-claudecode (CCG 다중제공자·skill 자동학습 성숙도 감시) | B |
<!-- origin: obra/superpowers@trend-source-registration | merged: 26/04/17 -->
<!-- origin: Yeachan-Heo/oh-my-claudecode@trend-source-registration | merged: 26/04/17 -->

### 실행 흐름

```
1. 소스별 최신 변경사항 수집 (WebSearch + WebFetch)
2. 현재 스택/rules/와의 관련성 필터링
3. 영향도 분류:
   🔴 Breaking: 즉시 대응 필요 (API 삭제, 보안 취약점)
   🟡 Update: 적용하면 이득 (성능 개선, 새 기능)
   🟢 Watch: 추적만 (실험적 기능, 커뮤니티 논의)
4. 🔴/🟡 항목 → 규칙 mutation 후보 생성
5. 사용자 확인 → rules/ 업데이트
```

### 산출물: 트렌드 브리프

```markdown
## 트렌드 브리프 — {날짜}

### 🔴 즉시 대응
- [소스] {변경 내용} → 영향: {어떤 rules/파일} → 제안: {mutation}

### 🟡 적용 권장
- [소스] {변경 내용} → 이점: {설명} → 제안: {mutation}

### 🟢 추적
- [소스] {변경 내용} → 메모
```

### harsh-critic 연동
트렌드에서 발견된 규칙 mutation은 적용 전:
- service-completion-checklist 통과 (이 변경이 작업 완료를 돕는가?)
- 기존 rules/ 규칙과 충돌 없는지 확인

---

## 크롤링 소스 레퍼런스

이 스킬은 사용자의 다음 크롤링 인프라와 연동 가능:

| 소스 | 크롤러 | 용도 |
|------|--------|------|
| **국가법령정보센터** | law_crawler.py (law.go.kr Open API) | 법규/고시/행정규칙 검색 |
| **KOSHA 재해사례** | data.go.kr API | 산업재해 사례, MSDS |
| **학술 DB (KCI/RISS/DBpia)** | 각 API | 한국 학술논문 |
| **Semantic Scholar / OpenAlex** | REST API | 글로벌 학술논문 |
| **Elicit** | MCP 서버 / API (Pro) | 체계적 문헌고찰 자동화 |

---

## 레퍼런스 프레임워크

| 출처 | 적용 부분 | 링크 |
|------|----------|------|
| **PRISMA 2020** | 전체 파이프라인 구조 | prisma-statement.org |
| **Elicit SR** | 스크리닝·추출 워크플로우 | elicit.com |
| **Wohlin 2014** | 스노우볼링 가이드라인 | wohlin.eu/ease14.pdf |
| **GRADE** | 근거 등급화 | gradepro.org |
| **Harness #44** | 시장 조사 Fan-out/Fan-in | revfactory/harness-100 |
| **Harness #100** | IMRaD 연구 보고서 | revfactory/harness-100 |
| **Harness #58** | Toulmin 모델 (논증 평가) | revfactory/harness-100 |
| **gstack /review** | 편집증적 구조 감사 | garrytan/gstack |
| **Anthropic MAS** | 오케스트레이터-워커 패턴 | anthropic.com/engineering |
| **Stanford STORM** | 다관점 연구 질문 생성 | storm-project.stanford.edu |

## DON'T
- 단일 출처로 결론 — 최소 2개 교차 검증 필수
- 포함/제외 기준 없이 전부 포함 — 양만 늘면 노이즈
- C/D 등급 근거를 A처럼 인용 — 등급 표기 없이 약한 근거로 강한 주장

## DO
- 검색 전 포함/제외 기준 먼저 정의
- 근거 등급(A강/B중/C약/D미확인) 반드시 표기
- 갭 맵(아직 모르는 것) 반드시 출력
