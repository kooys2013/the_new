---
name: pumeuiseo-generator
description: |
  품의서 PPT 생성기 — 반드시 사용: 품의서, 품의, 결재 문서, 품의서 써줘, 품의서 PPT, 공사 품의서 (단독). Generate 품의서 .pptx file. Do NOT use when full package needed (use pumui-package-generator).
---

# 품의서 자동 생성 스킬 (pumeuiseo-generator)

## 개요

Nitto/KORENO 사내 설비투자·안전·환경 공사 **품의서 PPT** (.pptx)를 자동 생성.
원본 예제 스타일(파란/빨간 Nitto 브랜드, Confidential 마크, 서머리 표, 간트 차트 등)을 충실히 재현.

---

## 실행 전 확인사항

먼저 사용자에게 아래 정보를 확인한다. **불명확한 항목만** 역질문 (최대 3개):

| 항목 | 설명 | 기본값 |
|------|------|--------|
| 공사명 | 품의서 제목 | (필수) |
| 총 금액 | 견적 합계 (M₩ 또는 M¥) | (필수) |
| 회의체 | KO전 / 부서장 결재 / 임원 결재 | KO전 |
| 승인자 | 이름 또는 직책 | 태전 |
| 보고자 | 이름 | 구유성 |
| 일자 | 보고 날짜 | 오늘 날짜 |
| 업체명 | 시공사 / 납품사 | (가능하면) |
| 스케줄 | 공사 기간 (월 단위) | (가능하면) |

> 사용자가 이미지(견적서, 현장 사진, 기존 PPT)를 첨부했다면 내용을 최대한 추출해 자동 채운다.

---

## 슬라이드 구성 (9슬라이드 고정)

| # | 슬라이드 | 핵심 내용 |
|---|---------|----------|
| 0 | **표지** | 제목, 회의체, 승인/보고자, 날짜, 부의사항, 의사결정기준 |
| 1 | **서머리** | 과제·원인·해결책·효과·코스트·스케줄·심의요청 요약표 |
| 2 | **공사개요** | 공사배경·범위·금액·사진 플레이스홀더·메이커 |
| 3 | **과제** | 문제점 표 + 리스크 목록 + 사진 플레이스홀더 |
| 4 | **원인** | 원인 분석표 + 법규/기술 근거 + 사진 플레이스홀더 |
| 5 | **해결책** | 해결 방안표 + 개념도 플레이스홀더 + 진행 순서 |
| 6 | **효과** | Before/After 비교 + 기대효과 카드 + 비교표 |
| 7 | **견적검토** | 예산 비교표 + 업체 선정 평가표 |
| 8 | **스케줄** | 월별 간트 차트 (2~3개월 기준) |

---

## 코드 생성 절차

**반드시 아래 순서를 따른다:**

### Step 1 - 정보 수집
사용자 입력 + 첨부파일에서 슬라이드별 내용을 추출·정리.

### Step 2 - pptxgenjs 스크립트 작성
`references/slide-template.md`의 코드 패턴을 기반으로 `/home/claude/pumeuiseo_output.js` 생성.

### Step 3 - 실행 및 검증
```bash
node /home/claude/pumeuiseo_output.js
python /mnt/skills/public/pptx/scripts/office/soffice.py --headless --convert-to pdf /home/claude/pumeuiseo.pptx
rm -f /home/claude/slide-*.jpg
pdftoppm -jpeg -r 150 /home/claude/pumeuiseo.pdf /home/claude/slide
ls -1 /home/claude/slide-*.jpg
```

### Step 4 - 시각적 QA
생성된 슬라이드 이미지를 `view` 도구로 확인. 문제 발견 시 수정 후 재실행.

### Step 5 - 파일 출력
```bash
# 파일명 형식: yymmddhhmm_공사명_품의서.pptx
cp /home/claude/pumeuiseo.pptx "/mnt/user-data/outputs/$(date +%y%m%d%H%M)_품의서.pptx"
```
`present_files` 도구로 사용자에게 전달.

---

## 디자인 규칙

자세한 코드 패턴은 `references/slide-template.md` 참고.

### 색상 팔레트
```
C_DARK_BLUE = "1F3864"   # 헤더·라벨 배경
C_MID_BLUE  = "2E5EA8"   # 강조 요소
C_LIGHT_BLUE= "BDD0EE"   # 라벨 셀 배경
C_RED       = "C00000"   # 경고·강조·Confidential
C_WHITE     = "FFFFFF"
C_GRAY_BG   = "F2F2F2"
C_ORANGE    = "FF6600"
```

### 공통 요소 (모든 슬라이드)
- **좌측 세로 악센트바**: 빨간(상단) + 파란(하단) 겹침 (x=0.2, w=0.1)
- **푸터**: 회사명 저작권 문구 + Nitto 로고 텍스트
- **Confidential 박스**: 좌하단 빨간 박스
- **페이지 번호**: 우상단

### 표 스타일
- 헤더 행: `C_MID_BLUE` 배경 + 흰색 텍스트 + bold
- 짝수 행: `"EEF3FB"` (연파랑)
- 홀수 행: `C_WHITE`
- 강조 행: `"FFF3CD"` (연노랑)
- 테두리: `"AAAAAA"`, pt=0.5

### 슬라이드별 핵심 제목 규칙
```
표지:   "YYYY년 MM월도 (회의체명)"
슬라이드 1: "【서머리】 본일의 보고 개요"
슬라이드 2: "(예산종류)공사명의 건"
슬라이드 3: "【과제】 ..."
슬라이드 4: "【원인】 ..."
슬라이드 5: "【해결책】 ..."
슬라이드 6: "【효과】 ..."
슬라이드 7: "【견적 검토】 투자예산 및 업체 선정 이유"
슬라이드 8: "【스케줄】"
```

---

## 참고 파일

- `references/slide-template.md` — 슬라이드별 pptxgenjs 코드 패턴 (반드시 읽을 것)

---

## 자주 쓰는 품의서 유형별 가이드

### 안전 개선 (Safety)
- 슬라이드 3 과제표: 설비/구분, 높이(M), 점검빈도, 위험성 등급 포함
- 슬라이드 6 효과: RA 랭크 Before→After (B→D 등) 매트릭스 포함
- 금액 단위: M¥ (엔화) 또는 M₩ 원화 병기, 환율 표기

### 환경 개선 (Environment)
- 슬라이드 3 과제표: 법규 조항, 위반 현황, 적발 리스크 포함
- 슬라이드 4 원인: 관련 법규 및 조문 명시
- 슬라이드 5 해결책: 환경공단 제안 방안 등 외부 기관 근거 포함

### 설비 투자 (Capex)
- 슬라이드 2: 레이아웃변경/보세/방화/PSM/관공서 체크박스 포함
- 슬라이드 7: TME vs 3GA 등 2개사 비교표 구성
- 예산 구분: 자재비/인건비/기타/합계 4행 고정
