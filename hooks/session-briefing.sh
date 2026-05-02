#!/bin/bash
# session-briefing.sh — 세션 시작 시 성장 메트릭 브리핑
# v2.5 Growth Engine #5: 능동적 제안

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
RULES_DIR="$CLAUDE_DIR/rules"

# 1. 교훈 수 카운트
LESSONS=0
if [ -f "$GLOBAL_MD" ]; then
  LESSONS=$(grep -c '^\- ' "$GLOBAL_MD" 2>/dev/null | tail -1 || echo 0)
fi

# 2. Rules 파일 수
RULES_COUNT=0
if [ -d "$RULES_DIR" ]; then
  RULES_COUNT=$(find "$RULES_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

# 3. 최근 세션에서 반복된 에러 (git log에서 fix: 커밋 카운트)
RECENT_FIXES=0
if command -v git &>/dev/null; then
  RECENT_FIXES=$(git log --oneline --since="7 days ago" --all 2>/dev/null | grep -ci 'fix' || echo 0)
fi

# 4. 성숙도 간이 계산
# 교훈 축적: 20개 이상이면 100%, 비례
LESSON_SCORE=$((LESSONS > 20 ? 100 : LESSONS * 5))
# 규칙 승격: 5개 이상이면 100%
RULES_SCORE=$((RULES_COUNT > 5 ? 100 : RULES_COUNT * 20))
# 평균
if [ $((LESSON_SCORE + RULES_SCORE)) -gt 0 ]; then
  MATURITY=$(( (LESSON_SCORE + RULES_SCORE) / 2 ))
else
  MATURITY=0
fi

# S5: jsonl 크기 경고 (50MB 초과 시 /clear 권고)
JSONL_WARN=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
  JSONL_MAX=$(find "$CLAUDE_PROJECT_DIR" -name "*.jsonl" -type f 2>/dev/null | xargs du -b 2>/dev/null | sort -rn | head -1 | awk '{print $1}')
  if [ -n "$JSONL_MAX" ] && [ "$JSONL_MAX" -gt 52428800 ]; then
    JSONL_MB=$(( JSONL_MAX / 1048576 ))
    JSONL_WARN="⚠ session jsonl ${JSONL_MB}MB (정상치 5MB) — /clear 권장"
  fi
fi

# 출력
echo "┌─── Growth Briefing ───────────────────────┐"
echo "│ 교훈: ${LESSONS}개 | Rules: ${RULES_COUNT}개 | 최근 fix: ${RECENT_FIXES}건"
echo "│ 간이 성숙도: ${MATURITY}%"

# 5. 제안 생성
if [ "$RECENT_FIXES" -gt 5 ]; then
  echo "│ ⚠ fix 커밋 ${RECENT_FIXES}건 — 반복 에러 점검 권장"
fi
if [ "$RULES_COUNT" -lt 3 ]; then
  echo "│ 💡 rules/ 파일 ${RULES_COUNT}개 — 교훈 승격 검토 권장"
fi
if [ "$LESSONS" -gt 30 ]; then
  echo "│ 💡 교훈 ${LESSONS}개 — CLAUDE.md 정리 권장 (200줄 제한)"
fi

# 5.5 Codex 자동 리뷰 상태 — state.json 기반 (최신성 우선, 마커는 폴백)
# v2.7: 자동 실행 결과가 있으면 [CODEX-AUTO] 신호로 Claude의 중복 /review 차단
CODEX_INFO=$(python3 - 2>/dev/null <<'PYEOF'
import json, pathlib, time, os

home = pathlib.Path.home()
pending = home / ".claude" / "_cache" / "codex-review-pending.json"
# 3 가지 state 루트 검색: openai-codex (기본), codex-inline (인라인 변종), tmp (폴백)
state_roots = [
    home / ".claude" / "plugins" / "data" / "codex-openai-codex" / "state",
    home / ".claude" / "plugins" / "data" / "codex-inline" / "state",
    pathlib.Path(os.environ.get("TEMP", "") or "/tmp") / "codex-companion",
]

# 전체 워크스페이스 중 가장 최근 job (createdAt 기준, jobs[0]이 최신)
latest_job = None
latest_mtime = 0
for root in state_roots:
    if not root.exists():
        continue
    for sj in root.glob("*/state.json"):
        try:
            mt = sj.stat().st_mtime
            if mt > latest_mtime:
                d = json.loads(sj.read_text(encoding="utf-8"))
                jobs = d.get("jobs", [])
                if jobs:
                    latest_mtime = mt
                    latest_job = jobs[0]  # sortJobsNewestFirst — 0번이 최신
        except Exception:
            continue

# 1시간 이내 작업만 유효
status_line = ""
if latest_job and (time.time() - latest_mtime) < 3600:
    status = latest_job.get("status", "")
    kind = latest_job.get("kind", "review")
    jid = latest_job.get("id", "")
    summary = (latest_job.get("summary") or "").replace("\n", " ").replace("|", " ")[:80]
    if status == "completed":
        status_line = f"DONE|{kind}|{jid}|{summary}"
    elif status == "running":
        status_line = f"RUNNING|{kind}|{jid}|"
    elif status == "failed":
        status_line = f"FAILED|{kind}|{jid}|"

# 마커 기반 폴백 (state.json 없거나 오래됨)
if not status_line and pending.exists():
    try:
        d = json.loads(pending.read_text(encoding="utf-8"))
        if d.get("code_files", 0) > 0:
            status_line = f"PENDING|{d.get('recommend','review')}|{d.get('sensitive_files',0)}|{d.get('recommend_cmd','/codex:review')}"
    except Exception:
        pass

print(status_line)
PYEOF
)
if [ -n "$CODEX_INFO" ]; then
  TYPE=$(echo "$CODEX_INFO" | cut -d'|' -f1)
  KIND=$(echo "$CODEX_INFO" | cut -d'|' -f2)
  ID_OR_SENS=$(echo "$CODEX_INFO" | cut -d'|' -f3)
  DETAIL=$(echo "$CODEX_INFO" | cut -d'|' -f4-)
  case "$TYPE" in
    DONE)
      echo "│ [CODEX-AUTO] ✅ ${KIND} 완료 — /review 생략 권장"
      echo "│    └ 결과: /codex:result ${ID_OR_SENS}"
      [ -n "$DETAIL" ] && echo "│    └ 요약: ${DETAIL}..."
      ;;
    RUNNING)
      echo "│ [CODEX-AUTO] ⏳ ${KIND} 진행중 — /codex:status 로 확인, /review 중복 금지"
      ;;
    FAILED)
      echo "│ [CODEX-AUTO] ❌ ${KIND} 실패 — 수동 /codex:${KIND} 재시도 가능"
      ;;
    PENDING)
      echo "│ [CODEX-AUTO] ⚠ 자동 실행 전/실패 — ${DETAIL}"
      ;;
  esac
fi

[ -n "$JSONL_WARN" ] && echo "│ $JSONL_WARN"
echo "└────────────────────────────────────────────┘"

# 5.7 Vibe mentor (설치 시 자동)
[ -x "$CLAUDE_DIR/hooks/vibe-mentor-brief.sh" ] && "$CLAUDE_DIR/hooks/vibe-mentor-brief.sh" 2>/dev/null || true

# 6. 병목 진단 5초 루틴 (v2.6)
echo "┌─── 병목 5초 루틴 (속도 안 날 때) ─────────┐"
echo "│ 1. 같은 에러 반복? → problem-solver Phase 2-A"
echo "│ 2. 파일 구조 모름? → /compact + Explore"
echo "│ 3. 방향 자체 모호? → unbounded-engine"
echo "│ 4. 도구 선택 불명? → rules/skill-quickref.md"
echo "│ 5. 모델 한계?     → model-strategy 에스컬레이션"
echo "└────────────────────────────────────────────┘"
