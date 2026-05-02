# Trading Antifragile — Taleb Barbell (GO 프로젝트 특화)

> 근거: Taleb 2012 *Antifragile*, 2007 *The Black Swan* / 2024-2026 Barbell 적용 사례
> 목적: "10x 렌즈" 적용 시 파멸 리스크를 정량 방어 — 특히 퀀트 트레이딩 도메인

---

## 0. 핵심 원리

| 개념 | 정의 | 트레이딩 적용 |
|------|------|--------------|
| **Fragile** | 변동성·충격에 손실 | 고레버리지 단일 심볼 올인 |
| **Robust** | 변동성에 무반응 | 저레버리지 분산 (연 5% 채권) |
| **Antifragile** | 변동성에서 이득 | 바벨 = 90% 현금·채권 + 10% 극공격 옵션 |

**핵심 공리**:
> "The probability of ruin is not the same as the expected loss."
> — 파멸 확률 > 0 이면 기대수익 무관하게 NO-GO

**Kelly Criterion 경고**:
- 풀 Kelly는 최적 성장률이지만 **파산 확률 매우 높음**
- 실전은 Quarter Kelly 또는 Fractional Kelly
- **"승률 70%·3:1 R/R" 조차도 풀 Kelly 적용 시 20% drawdown 확률 ≥ 50%**

---

## 1. 바벨(Barbell) 전략 — GO 프로젝트 배분 규칙

### 1.1 자산 배분 (전체 자본 기준)

| 분류 | 비중 | 수단 | 기대 수익 | 파멸 리스크 |
|------|------|------|----------|-------------|
| **Safe (90%)** | 88~92% | 현금·머니마켓·국채 | 연 3~5% | ~0 |
| **Reserve (5%)** | 3~7% | 대기 자금 (entry opportunity) | 0 | 0 |
| **Aggressive (5%)** | 3~7% | 레버리지 선물·옵션·알트 | 잠재 100~1000x | 100% (예상) |

**철칙**:
- Aggressive 트랜치는 **"영구 손실 가능"** 전제로 운용
- Aggressive 손실이 Safe 에 영향을 주는 fund flow 구조 금지
- "물타기" 금지 (Safe → Aggressive 자본 이동 = 바벨 붕괴)

### 1.2 트랜치 내부 바벨 (Aggressive 5% 내부에서 재적용)

GO v2 Track B 100종목 설정에서는 Aggressive 트랜치 내부에서도 바벨:

| 내부 분류 | 비중 | 운용 |
|-----------|------|------|
| **Core 80%** | 4% 자본 | 상위 상관성 낮은 20심볼 (유효 N 기반) |
| **Moonshot 20%** | 1% 자본 | 저유동성 고변동 알트 — 총 손실 각오 |

---

## 2. Ruin Risk 정량화

### 2.1 Kelly / Risk of Ruin 공식

**단순 공식** (대칭 승률):
```
P(ruin) = ((1 - edge) / (1 + edge)) ^ (bankroll / max_loss)
```

**예시** (edge = 0.10, max_loss = 2% bankroll):
- P(ruin) = (0.9/1.1)^50 ≈ 0.00009 ← 허용
- edge = 0.02 동일 조건 → P(ruin) ≈ 0.36 ← 절대 금지

### 2.2 퀀트 특화 ruin 시나리오

| 시나리오 | 메커니즘 | GO v2 방어 |
|---------|---------|-----------|
| **Flash Crash** | 슬리피지 × 레버리지 × 상관 spike | Kill Switch daily_pnl_limit |
| **거래소 파산** | 자본 동결 (FTX 2022, Mt.Gox 2014) | 다거래소 분산 · Safe 90% 은행 |
| **LLM 환각 지수** | 가짜 지표 기반 진입 | 실측 백테스트 + IS/OOS 분리 |
| **Black Swan** | 예측 불가 (COVID, LTCM 1998) | 바벨 구조 자체 방어 |
| **체제 전환** | 강세장 → 약세장 (백테 편향) | 체제 판별 + VALID+TEST 공통 통과 |

---

## 3. Convexity (컨벡시티) — Antifragile 측정

### 3.1 정의

```
convexity = ∂²(payoff) / ∂(volatility)²
```

- **convex > 0**: 변동성 증가 시 이익 가속 (롱 옵션, 바벨 Aggressive)
- **concave < 0**: 변동성 증가 시 손실 가속 (숏 옵션, 레버리지 롱)
- **linear**: 변동성 무관 (현물 보유)

### 3.2 GO v2 적용

| 전략 | convexity | 바벨 분류 |
|------|-----------|----------|
| Track B 롱 트레일링 (p_level) | 약간 convex (손절 고정 + 익절 무제한) | Aggressive Core |
| Track B 숏 트레일링 (k=0.40) | 약간 concave (변동성 상방 취약) | Aggressive Core |
| 신규 알트 진입 | concave (급락 위험) | Moonshot (비중 제한) |
| 현금 보유 | linear | Safe |

---

## 4. ruin risk 체크리스트 (신규 전략 도입 시)

unbounded-engine SKILL.md Phase 2 "10x 렌즈" 에서 호출됨.

```markdown
[ ] Q1: 이 전략의 최대 단일 거래 손실 = 자본의 ?%
[ ] Q2: N회 연속 손실 시 bankroll 0 도달 가능한가?
[ ] Q3: Kelly 공식 P(ruin) < 0.01 인가?
[ ] Q4: 바벨 구조가 유지되는가? (Aggressive 트랜치만 영향)
[ ] Q5: 거래소·브로커 파산 시 Safe 보호되는가?
[ ] Q6: 슬리피지·수수료 실측 후에도 edge > 0.05 인가?
[ ] Q7: 3개월 OOS 에서 재현되었는가?
[ ] Q8: 역사적 유사 사건(2008, 2020, 2022) 백테 대응되는가?
```

**PASS = 8/8 필수**. 하나라도 실패 시 비중 축소 또는 Moonshot 트랜치 이동.

---

## 5. GO v2 Phase 5 (100종목 · 일일 10%) 바벨 재평가

Stream A Phase 5.3 실측:
- BR=1.5% / MP=20 / MDD=37.46% / 일일 10% 달성률 22.9%

### 5.1 바벨 렌즈 판정

| 조건 | 검증 | 판정 |
|------|------|------|
| 자본의 100% 를 이 설정에 투입? | 대부분 실패 시나리오 | ❌ FRAGILE |
| Aggressive 트랜치 5% 로 제한? | MDD 37% × 5% = 자본 1.87% 손실 | ✅ ANTIFRAGILE |
| 일일 10% 달성률 22.9% + 복리 | 변동성에서 이득 | ✅ convex |
| Kill Switch OFF 상태 ROI | 과대측정 (실전 감쇠 30~50%) | ⚠️ 보정 필수 |

**결론**: Track B 100종목 공격 설정은 **Aggressive 트랜치 내부** 에서만 유효. 단독 전략으로 자본 100% 투입 금지.

### 5.2 권장 배분

```
전체 자본 $100,000 예시
├── Safe 90% = $90,000 (현금·국채·머니마켓)
├── Reserve 5% = $5,000 (기회 대기)
└── Aggressive 5% = $5,000
     ├── Core 80% = $4,000 (Track B 100종목 BR=1.5% MP=20)
     └── Moonshot 20% = $1,000 (초변동 알트 / 옵션)
```

---

## 6. 교훈 (Tactical DNA 후보)

- `[TRADING][BARBELL] WHEN 신규 공격 전략 도입 THEN 전체 자본 배분의 5~10% 상한 — ruin risk 는 기대수익 무관`
- `[TRADING][KELLY] WHEN Kelly 공식 적용 THEN Quarter Kelly 상한 — Full Kelly 파산 확률 50%+`
- `[TRADING][CONVEX] WHEN concave payoff 전략 THEN Moonshot 트랜치 배치 — Core 트랜치 진입 금지`
- `[TRADING][KILL] WHEN Kill Switch OFF 상태 ROI 보고 THEN 30~50% 감쇠 경고 병기 — 실전 괴리 축적 방지`

---

## 7. 참조

- Taleb, N. N. (2012). *Antifragile: Things That Gain from Disorder*
- Taleb, N. N. (2007). *The Black Swan: The Impact of the Highly Improbable*
- Thorp, E. O. (1969). *Optimal Gambling Systems for Favorable Games* (Kelly Criterion)
- MacLean, Thorp, Ziemba (2011). *The Kelly Capital Growth Investment Criterion*
- SKILL.md Phase 2 "10x 렌즈 ruin risk" 섹션과 교차 참조
- constraint-examples.md "Chesterton 체크 필요 사례" — 거래소 API 재시도 (L2 재분류)
