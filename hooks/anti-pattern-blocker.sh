#!/usr/bin/env bash
# anti-pattern-blocker.sh — PostToolUse(Edit|Write) 안티패턴 감지 + 경고
# coding-pattern-library AP 목록 기반 정규식 매칭
# 차단(exit 1) 아님 — additionalContext 경고만 (UX 보호)

set -euo pipefail

TOOL_INPUT=$(cat /dev/stdin 2>/dev/null || echo "{}")
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
inp = d.get('tool_input',{})
print(inp.get('file_path','') or inp.get('path',''))
" 2>/dev/null || echo "")

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

# AP-001: backtest_engine.py에서 coverage 관련 import
if echo "$FILE_PATH" | grep -q "backtest_engine\.py"; then
  if grep -qE "import (coverage|pytest_cov)" "$FILE_PATH" 2>/dev/null; then
    echo '{"additionalContext": "⚠️ [anti-pattern-blocker] AP-001: backtest_engine.py에 coverage import — 이 파일은 coverage 게이트 제외 대상입니다."}'
    exit 0
  fi
fi

# AP-002: 훅 파일에서 sleep (async 훅 지연)
if echo "$FILE_PATH" | grep -qE "hooks/.*\.sh$"; then
  if grep -qE "^[[:space:]]*(sleep [0-9])" "$FILE_PATH" 2>/dev/null; then
    echo '{"additionalContext": "⚠️ [anti-pattern-blocker] AP-003: hook 파일에서 sleep 사용 감지 — async 훅 전환 권장 (UX 블로킹 위험)"}'
    exit 0
  fi
fi

# AP-003: SKILL.md에서 model frontmatter 누락 감지
if echo "$FILE_PATH" | grep -q "SKILL\.md$"; then
  if ! grep -q "^model:" "$FILE_PATH" 2>/dev/null; then
    echo '{"additionalContext": "⚠️ [anti-pattern-blocker] v2 표준 미준수: SKILL.md에 model frontmatter 없음 → /skills-v2-migrator 실행 권장"}'
    exit 0
  fi
fi

exit 0
