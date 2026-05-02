# /mentor-mine

멘토 지식에서 HDBSCAN 기반으로 아이디어를 채굴합니다.

## 사용법

```
/mentor-mine dory          # Dory 지식 채굴 (dry-run)
/mentor-mine dory --save   # MemPalace에 결과 저장
/mentor-mine all --save    # 전 멘토 채굴 + cross-mentor 분석
```

## 실행 지시

$ARGUMENTS 파싱:
- 첫 번째 토큰 = mentor_id ("dory" | "emperor_btc" | "dante" | "all")
- "--save" 포함 시 MemPalace 저장 활성화

아래 순서로 실행:

### Step 1 — Python 채굴 실행 (Bash tool)

```bash
cd C:/Users/koo-ys/workspaces/GO/dory-knowledge
.venv/Scripts/python.exe C:/Users/koo-ys/workspaces/GO/mentor-knowledge-core/scripts/run_mining.py {mentor_id} {--save if requested} --json
```

출력 JSON을 파싱해 결과 요약 제시:
- 멘토별 클러스터 수 및 아이디어 ID 목록
- MemPalace 저장 건수
- cross-mentor consensus/contradiction 건수 (all 모드)

### Step 2 — 채굴 결과 해석 (Sonnet)

각 아이디어 클러스터에 대해:
1. `search_dory` 또는 `search_{mentor_id}` 도구로 대표 키워드 검색
2. similarity 기준으로 렌즈 판정 (✅/⚠️/❓)
3. 결과를 표로 출력:

| IDEA ID | 키워드 | 청크 수 | 날짜 범위 | 렌즈 예비 판정 |
|---------|--------|---------|----------|--------------|

### Step 3 — 다음 단계 안내

각 아이디어에 대해 권장 다음 액션:
- ✅ 렌즈: `/strategy-objectify {idea_id}` → Sonnet이 전략 객체 변환
- ⚠️ 렌즈: 추가 search_dory로 상세 검증 필요
- ❓ 렌즈: 도리님 KB 미확인 → 독립 연구 먼저

## 아키텍처

```
run_mining.py
  → mentors_core/mining.py        # HDBSCAN 클러스터링
      → VectorStore._scroll_all() # Qdrant 전체 청크 로드
      → hdbscan.HDBSCAN.fit()    # 클러스터링
      → cluster_to_drawer()       # MemPalace 포맷 변환
  → MemPalace wing_knowledge/idea # 결과 저장
```

## 관련 파일

- `mentor-knowledge-core/mentors_core/mining.py` — 핵심 엔진
- `mentor-knowledge-core/scripts/run_mining.py` — CLI
- `~/.mentors/dory.yaml` — 멘토 설정
- `vault/public/harness/sops/dory-idea-mining-sop.md` — 채굴 후 SOP
