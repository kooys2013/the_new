# 품의서 pptxgenjs 코드 패턴 레퍼런스

이 파일은 각 슬라이드 유형별 실제 pptxgenjs 코드 패턴을 담고 있다.
스크립트 생성 시 이 패턴을 기반으로 내용만 교체해서 사용한다.

---

## 기본 설정 (모든 스크립트 공통 헤더)

```javascript
const pptxgen = require("pptxgenjs");
let pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';

// ─── 색상 상수 ───
const C_DARK_BLUE = "1F3864";
const C_MID_BLUE  = "2E5EA8";
const C_LIGHT_BLUE= "BDD0EE";
const C_RED       = "C00000";
const C_WHITE     = "FFFFFF";
const C_BLACK     = "000000";
const C_ORANGE    = "FF6600";

// ─── 공통 함수: 푸터 ───
function addFooter(slide) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.35, w: 10, h: 0.02,
    fill: { color: "AAAAAA" }, line: { color: "AAAAAA" }
  });
  slide.addText("© Korea Nitto Optical Co., Ltd. All Rights Reserved.", {
    x: 0.2, y: 5.37, w: 6, h: 0.2,
    fontSize: 7, color: "888888", align: "left"
  });
  slide.addText("Nitto", {
    x: 8.2, y: 5.3, w: 1.6, h: 0.3,
    fontSize: 18, bold: true, color: C_MID_BLUE, italic: true, align: "right"
  });
  slide.addText("Innovation for Customers", {
    x: 7.5, y: 5.55, w: 2.4, h: 0.15,
    fontSize: 6.5, color: "666666", align: "right"
  });
}

// ─── 공통 함수: Confidential 마크 ───
function addConfidential(slide) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 5.2, w: 0.9, h: 0.22,
    fill: { color: C_RED }, line: { color: C_RED }
  });
  slide.addText("Confidential", {
    x: 0.2, y: 5.2, w: 0.9, h: 0.22,
    fontSize: 7.5, color: C_WHITE, bold: true, align: "center", valign: "middle"
  });
}

// ─── 공통 함수: 슬라이드 제목 (좌측 악센트바 + 텍스트) ───
function addSlideTitle(slide, titleText, pageNum) {
  // 좌측 파란 세로 바
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 0.12, w: 0.1, h: 0.65,
    fill: { color: C_MID_BLUE }, line: { color: C_MID_BLUE }
  });
  // 상단 빨간 오버레이
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 0.12, w: 0.1, h: 0.25,
    fill: { color: C_RED }, line: { color: C_RED }
  });
  slide.addText(titleText, {
    x: 0.38, y: 0.1, w: 8.8, h: 0.72,
    fontSize: 22, bold: true, color: C_BLACK, valign: "middle"
  });
  if (pageNum !== undefined) {
    slide.addText(String(pageNum), {
      x: 9.5, y: 0.1, w: 0.45, h: 0.35,
      fontSize: 16, bold: true, color: C_BLACK, align: "right"
    });
  }
}
```

---

## 슬라이드 0: 표지 (Cover)

```javascript
{
  let slide = pres.addSlide();
  slide.background = { color: C_WHITE };

  // 상단 날짜/회의체
  slide.addText("2026년  2월도 (KO전)", {
    x: 0.3, y: 0.1, w: 5, h: 0.4,
    fontSize: 14, color: C_BLACK
  });

  // 기밀 빨간 박스 (우상단)
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 8.8, y: 0.1, w: 1.0, h: 0.28,
    fill: { color: C_RED }, line: { color: C_RED }
  });
  slide.addText("丸 秘", {
    x: 8.8, y: 0.1, w: 1.0, h: 0.28,
    fontSize: 10, color: C_WHITE, bold: true, align: "center", valign: "middle"
  });
  // 안전·환경 개선 건은 "Confidential"로 대체 가능

  // 좌측 악센트바 (파란+빨강)
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 1.3, w: 0.18, h: 1.5,
    fill: { color: C_MID_BLUE }, line: { color: C_MID_BLUE }
  });
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.3, y: 1.3, w: 0.18, h: 0.5,
    fill: { color: C_RED }, line: { color: C_RED }
  });

  // 메인 제목
  slide.addText("공사명의 건", {
    x: 0.6, y: 1.2, w: 9.0, h: 1.8,
    fontSize: 34, bold: true, color: C_BLACK, valign: "middle"
  });

  // 승인/보고자/날짜
  slide.addText([
    { text: "승인 : (KORENO)(승인자명)", options: { breakLine: true } },
    { text: "보고 : (KORENO)(생기2팀)(보고자명)", options: { breakLine: true } },
    { text: "2026년  2월  XX일" }
  ], {
    x: 0.5, y: 3.1, w: 5, h: 1.0,
    fontSize: 13, color: C_BLACK, lineSpacingMultiple: 1.4
  });

  // 부의사항 / 의사결정기준
  slide.addText([
    { text: "■ 부의사항", options: { bold: true, breakLine: true } },
    { text: "  본 투자 (총액 : XX.XXM₩)", options: { breakLine: true } },
    { text: " ", options: { breakLine: true } },
    { text: "■ 의사결정기준", options: { bold: true, breakLine: true } },
    { text: "  설비투자 5백만엔 이상~1천만엔 미만···(KO전)결의" }
  ], {
    x: 5.5, y: 3.1, w: 4.3, h: 1.3,
    fontSize: 12, color: C_BLACK, lineSpacingMultiple: 1.4
  });

  // Nitto 로고
  slide.addText("Nitto", {
    x: 4.0, y: 4.5, w: 2.5, h: 0.7,
    fontSize: 42, bold: true, color: C_MID_BLUE, italic: true, align: "center"
  });
  slide.addText("Innovation for Customers", {
    x: 3.8, y: 5.1, w: 3.0, h: 0.25,
    fontSize: 10, color: "666666", align: "center"
  });

  addFooter(slide);
}
```

---

## 슬라이드 1: 서머리 (Summary)

```javascript
{
  let slide = pres.addSlide();
  slide.background = { color: C_WHITE };
  addSlideTitle(slide, "【서머리】 본일의 보고 개요", 1);

  // 파란 헤더 박스
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 0.88, w: 9.6, h: 0.42,
    fill: { color: C_DARK_BLUE }, line: { color: C_DARK_BLUE }
  });
  slide.addText("공사명의 건", {
    x: 0.2, y: 0.88, w: 9.6, h: 0.42,
    fontSize: 14, bold: true, color: C_WHITE, align: "center", valign: "middle"
  });

  // 7행 요약표
  const rows = [
    { label: "과  제", content: "과제 내용" },
    { label: "원  인", content: "원인 내용" },
    { label: "해결책", content: "해결책 내용" },
    { label: "효  과", content: "효과 내용" },
    { label: "코스트", content: "XX.XXM₩ (안전/B투자)" },
    { label: "스케줄", content: "XX년 XX월 기안, XX년 XX월 설치공사 완료" },
    { label: "심의 요청 사항", content: '"공사명의 건"에 대해 심의해 주시기 바랍니다.' }
  ];

  const startY = 1.35;
  const rowH   = 0.56;
  const lW     = 1.15;
  const rW     = 8.45;

  rows.forEach((row, i) => {
    const y = startY + i * rowH;
    const isLast = i === rows.length - 1;
    const bgFill = i % 2 === 0 ? "EEF3FB" : C_WHITE;

    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.2, y, w: lW, h: rowH,
      fill: { color: C_LIGHT_BLUE }, line: { color: "AAAAAA", pt: 0.5 }
    });
    slide.addText(row.label, {
      x: 0.2, y, w: lW, h: rowH,
      fontSize: 10.5, bold: true, color: C_DARK_BLUE,
      align: "center", valign: "middle"
    });

    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.2 + lW, y, w: rW, h: rowH,
      fill: { color: isLast ? "FFF3CD" : bgFill }, line: { color: "AAAAAA", pt: 0.5 }
    });
    slide.addText(row.content, {
      x: 0.35 + lW, y: y + 0.03, w: rW - 0.2, h: rowH - 0.05,
      fontSize: 10, color: C_BLACK, valign: "middle", lineSpacingMultiple: 1.25
    });
  });

  addConfidential(slide);
  addFooter(slide);
}
```

---

## 슬라이드 2: 공사 개요

```javascript
{
  let slide = pres.addSlide();
  slide.background = { color: C_WHITE };
  addSlideTitle(slide, "(경비/안전/투자)공사명의 건", 2);

  // 체크박스 영역 (레이아웃변경/보세/방화/PSM/관공서)
  const tags = ["레이아웃변경", "보세", "방화", "PSM", "관공서"];
  tags.forEach((t, i) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.2 + i * 1.5, y: 0.85, w: 1.4, h: 0.22,
      fill: { color: "E8E8E8" }, line: { color: "AAAAAA", pt: 0.5 }
    });
    slide.addText(t, {
      x: 0.2 + i * 1.5, y: 0.85, w: 1.4, h: 0.22,
      fontSize: 8, color: C_BLACK, align: "center", valign: "middle"
    });
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 0.2 + i * 1.5, y: 1.07, w: 1.4, h: 0.18,
      fill: { color: C_WHITE }, line: { color: "AAAAAA", pt: 0.5 }
    });
  });

  // 좌측 "공사(구매)내용" 라벨
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 1.3, w: 1.5, h: 2.5,
    fill: { color: C_DARK_BLUE }, line: { color: C_DARK_BLUE }
  });
  slide.addText("공사\n(구매)\n내용", {
    x: 0.2, y: 1.3, w: 1.5, h: 2.5,
    fontSize: 16, bold: true, color: C_WHITE,
    align: "center", valign: "middle", lineSpacingMultiple: 1.5
  });

  // 공사 내용 텍스트 박스
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 1.7, y: 1.3, w: 8.1, h: 2.5,
    fill: { color: "EEF3FB" }, line: { color: "AAAAAA", pt: 0.5 }
  });

  // 불릿 항목들 (내용에 맞게 수정)
  const contentLines = [
    { label: "◆ 공사 배경", body: "공사 배경 내용" },
    { label: "◆ 공사 범위", body: "공사 범위 내용" },
    { label: "◆ 공사 예정일", body: "20XX년 XX월 중" },
    { label: "◆ 진행금액", body: "₩XX,XXX,XXX (VAT 별도)" },
    { label: "● 사용예산", body: "통상/안전/경비 예산 / 예산NO. (XXXXXXBR)", isRed: true }
  ];

  let cy = 1.38;
  contentLines.forEach(cl => {
    slide.addText([
      { text: cl.label + "  ", options: { bold: true, color: cl.isRed ? C_RED : C_DARK_BLUE } },
      { text: cl.body, options: { color: C_BLACK } }
    ], {
      x: 1.85, y: cy, w: 7.8, h: 0.44,
      fontSize: 9.5, valign: "middle", lineSpacingMultiple: 1.2
    });
    cy += 0.48;
  });

  // 하단 "도면 및 사진" 라벨
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.2, y: 3.85, w: 1.5, h: 1.3,
    fill: { color: C_DARK_BLUE }, line: { color: C_DARK_BLUE }
  });
  slide.addText("도면 및\n사진", {
    x: 0.2, y: 3.85, w: 1.5, h: 1.3,
    fontSize: 14, bold: true, color: C_WHITE,
    align: "center", valign: "middle", lineSpacingMultiple: 1.5
  });

  // 사진 플레이스홀더 3개 (실제 파일 경로로 교체 가능)
  for (let i = 0; i < 3; i++) {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: 1.85 + i * 2.55, y: 3.85, w: 2.4, h: 1.1,
      fill: { color: "CCCCCC" }, line: { color: "888888", pt: 0.5 }
    });
    slide.addText("[ 현장 사진 ]", {
      x: 1.85 + i * 2.55, y: 3.85, w: 2.4, h: 0.75,
      fontSize: 9, color: "555555", align: "center", valign: "middle"
    });
    slide.addText(`사진 캡션 ${i+1}`, {
      x: 1.85 + i * 2.55, y: 4.6, w: 2.4, h: 0.35,
      fontSize: 7.5, color: C_BLACK, align: "center", valign: "top"
    });
  }

  // 메이커 박스
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 9.45, y: 3.85, w: 0.35, h: 1.3,
    fill: { color: C_DARK_BLUE }, line: { color: C_DARK_BLUE }
  });
  slide.addText("메\n이\n커", {
    x: 9.45, y: 3.85, w: 0.35, h: 1.3,
    fontSize: 9, bold: true, color: C_WHITE,
    align: "center", valign: "middle"
  });
  slide.addText("업체명", {
    x: 8.6, y: 3.85, w: 0.85, h: 1.3,
    fontSize: 11, bold: true, color: C_DARK_BLUE,
    align: "center", valign: "middle"
  });

  addConfidential(slide);
  addFooter(slide);
}
```

---

## 슬라이드 7: 견적 검토 (2사 비교 버전)

```javascript
{
  let slide = pres.addSlide();
  addSlideTitle(slide, "【견적 검토】 투자예산 및 업체 선정 이유", 7);

  // 부제목
  slide.addText("복수업체 견적을 비교한 결과, (업체A)는 (업체B)보다 전체 공사비가 더 저렴하여 적정하다 판단", {
    x: 0.2, y: 0.86, w: 9.6, h: 0.5,
    fontSize: 10.5, bold: true, color: C_MID_BLUE, underline: true,
    align: "center", valign: "middle"
  });

  // 예산 표 (4행: 자재비/인건비/기타/합계)
  const budgetRows = [
    { label: "구분",   val1: "업체A",            val2: "업체B",            note: "검토 내용" },
    { label: "자재비", val1: "X.XXM¥",           val2: "X.XXM¥",           note: "업체B 자재비가 높음" },
    { label: "인건비", val1: "X.XXM¥",           val2: "X.XXM¥",           note: "인원·공수 동등 수준" },
    { label: "기타",   val1: "X.XXM¥",           val2: "X.XXM¥",           note: "간접비/기업이익 포함" },
    { label: "합계",   val1: "X.XXM¥ (선정)",    val2: "X.XXM¥",           note: "업체A가 약 X.XX M¥ 저렴" }
  ];
  // → 위 값들을 실제 금액으로 채운다

  // 업체 선정 평가표 (5점척도: ○=5, △=3, ✕=1)
  const selRows = [
    ["업체", "공기", "실적", "품질", "코스트", "판정"],
    ["업체A명", "○(1개월)", "○(다수)", "○(상)", "○(비교에서)", "20"],
    ["업체B명", "○(1개월)", "○(다수)", "△(중)",  "△(비교에서)", "16"]
  ];
}
```

---

## 슬라이드 8: 스케줄 (간트 차트)

```javascript
{
  let slide = pres.addSlide();
  addSlideTitle(slide, "【스케줄】", 8);

  // 부제목
  slide.addText("25년 12월 중순 발주, 26년 1월까지 설치공사를 완료하여 운영할 예정", {
    x: 0.2, y: 0.86, w: 9.6, h: 0.35,
    fontSize: 12, bold: true, color: C_MID_BLUE, underline: true, align: "center"
  });

  /*
  간트 차트 구성 패턴:
  - months: 표시할 월 배열 (예: ["11월", "12월", "1월"])
  - weeks: 각 월의 주차 (1W~4W, 총 months.length × 4)
  - schedRows: 각 행의 라벨과 간트 바 범위

  bars 배열의 각 항목:
  { start: 주차인덱스(0-based), end: 주차인덱스, month: 월인덱스 }

  star 항목 (의사결정/설치 완료 시점):
  { week: 주차인덱스, month: 월인덱스, text: "★ 날짜 (설명)" }
  */

  const schedRows = [
    { label: "의사결정", bars: [],                  star: { week: 3, month: 0, text: "★ 25년 11월 24일 (KO전 보고)" } },
    { label: "가격 검토", bars: [{ start: 0, end: 2, month: 1 }] },
    { label: "발주",     bars: [{ start: 2, end: 3, month: 1 }] },
    { label: "설치 제작", bars: [{ start: 3, end: 4, month: 1 }, { start: 0, end: 1, month: 2 }] },
    { label: "공사",     bars: [{ start: 1, end: 4, month: 2 }], note: "*설비 정지 불요" },
    { label: "설치",     bars: [],                  star: { week: 3, month: 2, text: "★" } }
  ];
}
```

---

## 사진 실제 삽입 방법 (플레이스홀더 교체)

사용자가 사진을 첨부한 경우 아래처럼 base64로 읽어서 삽입:

```javascript
const fs = require("fs");

// 이미지를 base64로 읽기
const imgData = fs.readFileSync("/path/to/photo.jpg");
const base64  = "image/jpeg;base64," + imgData.toString("base64");

// 플레이스홀더 대신 실제 이미지 삽입
slide.addImage({
  data: base64,
  x: 1.85, y: 3.85, w: 2.4, h: 1.1,
  sizing: { type: "cover", w: 2.4, h: 1.1 }
});
```

---

## RA 리스크 매트릭스 (안전 품의서 슬라이드 6용)

```javascript
// 5×5 매트릭스 (가능성 × 중대성)
// 색상 맵: S=빨강, A=주황, B=보라, C=노랑, D=회색
const rankColors = {
  "S": "FF0000", "A": "FF6600", "B": "9900CC",
  "C": "FFCC00", "D": "AAAAAA"
};
const matrix = [
  // [col1, col2, col3, col4, col5] → 중대성 1~5
  ["D","D","D","D","D"],  // 가능성 1
  ["D","C","C","B","A"],  // 가능성 2  ← 현재 위치 표시 가능
  ["D","C","B","A","A"],  // 가능성 3
  ["D","C","B","A","S"],  // 가능성 4
  ["D","B","A","S","S"],  // 가능성 5
];

const cellSize = 0.42;
const matrixX  = 0.3;
const matrixY  = 1.9;

matrix.forEach((row, ri) => {
  row.forEach((rank, ci) => {
    slide.addShape(pres.shapes.RECTANGLE, {
      x: matrixX + ci * cellSize,
      y: matrixY + (4 - ri) * cellSize,  // 위에서 아래로 역순
      w: cellSize, h: cellSize,
      fill: { color: rankColors[rank] },
      line: { color: C_WHITE, pt: 0.5 }
    });
    slide.addText(rank, {
      x: matrixX + ci * cellSize,
      y: matrixY + (4 - ri) * cellSize,
      w: cellSize, h: cellSize,
      fontSize: 9, color: C_WHITE, bold: true,
      align: "center", valign: "middle"
    });
  });
});

// 현재/개선후 위치 표시 (원형 마커)
// Before: 가능성2, 중대성4 → ci=3, ri=1
slide.addShape(pres.shapes.OVAL, {
  x: matrixX + 3 * cellSize + 0.03,
  y: matrixY + (4-1) * cellSize + 0.03,
  w: cellSize - 0.06, h: cellSize - 0.06,
  line: { color: C_BLACK, pt: 2 },
  fill: { type: "none" }
});
```

---

## 주의사항 (pptxgenjs 버그 방지)

1. **hex 색상에 `#` 절대 금지** → `"C00000"` ✅ / `"#C00000"` ❌
2. **shadow에 8자리 hex 금지** → `opacity` 프로퍼티 별도 사용
3. **bullet은 `bullet: true`** → 유니코드 `"•"` 사용 금지
4. **shadow 객체 재사용 금지** → 매번 `makeShadow()` 함수로 새 객체 생성
5. **`ROUNDED_RECTANGLE` + 직각 악센트바 조합 금지** → `RECTANGLE` 사용
6. **다국어(한글/일본어) 텍스트** → `fontFace` 지정 불필요, pptxgenjs가 자동 처리
