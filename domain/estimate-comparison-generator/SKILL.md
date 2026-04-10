---
name: estimate-comparison-generator
description: |
  견적 비교표 생성기 — 반드시 사용: 견적 비교, 업체 비교, 견적서 비교, 두 업체, A안 B안 비교, 견적비교표. Generate Excel (.xlsx) comparison of vendor estimates. Do NOT use for single-vendor estimates.
---

# 견적 비교 검토서 생성 스킬

## 개요

사용자가 입력한 정보를 바탕으로 **좌측(업체1) / 우측(업체2)** 2열 비교 구조의
견적 검토서 Excel(.xlsx)을 생성한다.

---

## 1. 사용자로부터 수집할 입력 정보

사용자가 제공하지 않은 항목은 반드시 질문하여 확인하라. 단, 한 번에 3개 이하로 질문하라.

### 필수 항목
| 항목 | 설명 |
|------|------|
| 문서번호 | 예: KEKIO-002 |
| 작성일 | 예: 2025-11-14 |
| 건명 | 공사/개선 제목 |
| 예산구분 | □전략 / ■통상 / □경비 중 선택 |
| 발표자 | 소속 + 이름 |
| 납기 | 예: 2025년 12월중 |
| 지불조건 | 예: 계약금 30%, 잔금 70% |
| 업체명 1 (좌측) | 예: TME |
| 업체명 2 (우측) | 예: 3GA |
| 공사 내용 요약 | 두 업체 공통 또는 각각 |

### 견적 내역
각 구분(섹션)마다 아래 형식으로 입력:
- **구분명**: 예) "1. H2동 보일러실"
- **항목별**: 재료비/노무비/간접비로 분류
  - 내역명, 규격, 수량(업체1), 단위, 단가(업체1), 수량(업체2), 단위, 단가(업체2)
  - 검토 코멘트 (해당 항목 우측에 표시)

### ⚠️ 내역 표기 규칙 — 품명과 규격 결합

견적 검토서의 **C열(내역)** 셀에 입력할 때, 품명과 규격을 반드시 아래 형식으로 결합하여 표기한다:

```
{품명}_{규격}
```

**예시:**
| 원본 품명 | 원본 규격 | 검토서 표기 |
|-----------|-----------|-------------|
| 메탈가스켓(20K) | 250A | 메탈가스켓(20K)_250A |
| 백 강관 파이프(25A) | 6M | 백 강관 파이프(25A)_6M |
| 코팅 와이어 로프(8mm) | 스텐 PVC | 코팅 와이어 로프(8mm)_스텐 PVC |
| 볼밸브(10K) | 50A | 볼밸브(10K)_50A |

**규칙 상세:**
- 규격 정보가 있는 경우: 반드시 `_`(언더스코어)로 연결
- 규격 정보가 없는 경우(노무비 항목 등): 품명만 표기, `_` 불필요
- 규격이 이미 품명 괄호 안에 포함된 경우(예: 백 강관 파이프(25A)): 추가 규격이 있으면 뒤에 덧붙임, 없으면 품명만 사용
- 사용자가 품명과 규격을 별도로 제공한 경우 무조건 결합하여 표기

**Python 코드 패턴:**
```python
def format_item_name(품명: str, 규격: str = '') -> str:
    """품명과 규격을 결합하여 내역 셀 표기 문자열 반환"""
    if 규격 and 규격.strip():
        return f"{품명.strip()}_{규격.strip()}"
    return 품명.strip()

# 사용 예
item_name = format_item_name('메탈가스켓(20K)', '250A')  # → '메탈가스켓(20K)_250A'
item_name = format_item_name('잡철공', '')               # → '잡철공'
```

### 총계 하단 항목
- 합계, 디스카운트, 발주 금액
- 견적 검토 의견 (불릿 형식 ■)
- 참석자 검토 의견
- 환경영향평가표 의견
- 업체이원화 관련

---

## 2. 출력 파일 구조 (Excel 레이아웃)

### 열 구성 (B~L)
```
B열: 구분 (재료비/노무비/간접비/합계 등)
C열: 내역
D열: 수량 (업체1)
E열: 단위 (업체1)
F열: 단가 (업체1)
G열: 견적금액 (업체1) = D*F (수식)
H열: 수량 (업체2)
I열: 단위 (업체2)
J열: 단가 (업체2)
K열: 견적금액 (업체2) = H*J (수식)
L열: 검토내용 (코멘트)
```

### 헤더 행 구성 (Row 1~12)
```
Row 1:  우상단 문서번호
Row 2:  건명
Row 3:  작성일
Row 4:  참석인원
Row 5:  예산구분
Row 6:  발표자
Row 7:  납기
Row 8:  지불조건
Row 9:  확인자 행
Row 10: 업체명 헤더 (B:업체명, D-G:업체1명, H-K:업체2명, L:검토내용)
Row 11: 공사내용
Row 12: 컬럼 헤더 (구분/내역/수량/단위/단가/견적금액 ×2 /검토내용)
```

### 섹션 구조 (본문)
각 공사 구분(예: "1. H2동 보일러실")마다:
- 소계 행: G열=SUM(해당 범위), K열=SUM(해당 범위)
- 재료비 항목들
- 노무비 항목들

### 합계 섹션 (하단)
```
간접비 섹션 → 합계 금액 행 → Discount → (Discount율) → 발주 금액
```

### 의견란 (최하단)
- 견적 검토 의견: ■ 불릿으로 여러 줄
- 참석자 검토 의견
- 환경영향평가표 의견
- 업체이원화 관련

---

## 3. Excel 생성 코드 패턴

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = Workbook()
ws = wb.active
ws.title = "견적비교"

# 열 너비 설정
col_widths = {
    'A': 2, 'B': 18, 'C': 38, 'D': 8, 'E': 6,
    'F': 12, 'G': 14, 'H': 8, 'I': 6,
    'J': 12, 'K': 14, 'L': 28
}
for col, width in col_widths.items():
    ws.column_dimensions[col].width = width

# 스타일 정의
header_fill = PatternFill("solid", fgColor="D9E1F2")   # 헤더 배경 (연파랑)
section_fill = PatternFill("solid", fgColor="F2F2F2")  # 구분 행 (연회색)
total_fill   = PatternFill("solid", fgColor="FFF2CC")  # 합계 행 (연노랑)
thin = Side(style='thin')
border = Border(left=thin, right=thin, top=thin, bottom=thin)

bold_font = Font(bold=True)
center = Alignment(horizontal='center', vertical='center')
right  = Alignment(horizontal='right',  vertical='center')
wrap   = Alignment(wrap_text=True, vertical='center')

# 숫자 포맷 (천단위 콤마)
num_fmt = '#,##0'

# 수식 패턴 예시 (소계 행)
# ws['G13'] = '=SUM(G14:G35)'
# ws['K13'] = '=SUM(K14:K35)'
# 항목 행
# ws['G14'] = '=D14*F14'
# ws['K14'] = '=H14*J14'

# 합계 행 (여러 섹션 소계 합산)
# ws['G112'] = '=SUM(G13,G36,G57,...)'
```

---

## 4. 서식 규칙

| 요소 | 규칙 |
|------|------|
| 헤더(업체명/컬럼명) | 굵게(Bold), 연파랑 배경, 가운데 정렬 |
| 구분 행(섹션 제목) | 굵게, 연회색 배경, 셀 병합(B:C) |
| 금액 열(F/G/J/K) | 숫자 서식 `#,##0`, 오른쪽 정렬 |
| 소계 행 | 굵게, 연노랑 배경 |
| 합계 행 | 굵게, 전체 테두리 |
| 검토내용(L열) | 줄바꿈 허용(wrap_text=True) |
| 전체 셀 | thin 테두리 |

---

## 5. 처리 흐름

1. **사용자 입력 수집** (질문으로 필수 항목 확인)
2. **Excel 파일 생성** (openpyxl 사용)
   - 헤더 섹션 작성
   - 각 공사 구분 섹션 반복 작성
   - 간접비 + 합계 섹션
   - 의견란 작성
3. **수식 삽입** (금액 = 수량 × 단가, 소계, 합계 모두 Excel 수식으로)
4. **서식 적용** (스타일, 병합, 열너비)
5. **파일 저장** → `/mnt/user-data/outputs/yymmddhhmm_견적비교검토서_건명.xlsx`
6. **present_files** 로 사용자에게 전달

---

## 6. 파일명 규칙

```
{KST yymmddhhmm}_{건명 요약}_견적비교검토서.xlsx
예) 2603161430_추락사고방지안전개선_견적비교검토서.xlsx
```

---

## 7. 출력 후 안내 메시지

파일 제공 후 간단히 아래를 안내하라:
- 합계 금액 비교 (업체1 vs 업체2)
- 핵심 차이점 요약 (단가/공수/항목 누락 등)
- 추천 업체 또는 추가 검토 필요 항목
