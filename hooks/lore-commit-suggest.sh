#!/usr/bin/env bash
# lore-commit-suggest.sh — PostToolUse(Write|Edit) hook
# 민감 파일 변경 감지 시 다음 commit에 /lore-commit 사용 권고를 additionalContext로 노출.
# 사용자 선호: hook 자동 권고 우선, 수동 슬래시 fallback.

# stdin JSON 파싱 (jq-free, python 3 사용)
PAYLOAD="$(cat 2>/dev/null || true)"
if [[ -z "$PAYLOAD" ]]; then exit 0; fi

# tool_input.file_path 추출
FILE_PATH="$(printf '%s' "$PAYLOAD" | python -c "import sys,json
try:
    d=json.load(sys.stdin)
    ti=d.get('tool_input',{}) or {}
    print(ti.get('file_path','') or ti.get('path','') or '')
except Exception:
    print('')
" 2>/dev/null)"

# 비어있으면 조용히 종료 (성공은 침묵)
if [[ -z "$FILE_PATH" ]]; then exit 0; fi

# 민감 파일 패턴 매칭 (소문자)
LOWER="$(printf '%s' "$FILE_PATH" | tr '[:upper:]' '[:lower:]')"
SENSITIVE=0
case "$LOWER" in
  *auth*|*rls*|*migration*|*schema*.sql|*/sql/*.sql|*strategy_config*|*backtest_engine*|*ngram_engine*|*htf_levels*|*portfolio_simulator*|*risk_*.py|*canary*|*deployment*.yaml|*kubeconfig*|*terraform/*.tf)
    SENSITIVE=1 ;;
esac

if [[ "$SENSITIVE" -eq 0 ]]; then exit 0; fi

# additionalContext로 권고 출력 (Stop/PostToolUse는 stdout = additionalContext)
cat <<EOF
┌─── 결정 영속성 권고 ─────────────────────────────────────┐
│ 민감 파일 변경 감지: $(basename "$FILE_PATH")
│ 다음 commit에 /lore-commit 사용 권장:
│   /lore-commit "<제목>" \\
│     --why="이 변경이 왜 필요한가"  \\
│     --decision="무엇을 채택했나"     \\
│     --alternatives="고려했던 대안 + 거부 사유"
│ → 1년 후 git log --grep "Decision:" 으로 회수 가능
└──────────────────────────────────────────────────────────┘
EOF

exit 0
