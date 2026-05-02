#!/bin/bash
# Claude Code Slack 알림 스크립트
# $1 = 이벤트 타입 (requesting-permission | completed)

WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"  # 환경변수로 주입: export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
EVENT_TYPE="${1:-unknown}"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
WORKING_DIR="${2:-$(pwd)}"

case "$EVENT_TYPE" in
  "requesting-permission")
    EMOJI="🔐"
    TITLE="권한 요청 발생"
    COLOR="#FF6B35"
    ;;
  "completed")
    EMOJI="✅"
    TITLE="작업 완료"
    COLOR="#36A64F"
    ;;
  *)
    EMOJI="ℹ️"
    TITLE="Claude Code 이벤트"
    COLOR="#0099FF"
    ;;
esac

# Slack 메시지 전송
curl -s -X POST -H 'Content-type: application/json' \
  --data "{
    \"attachments\": [{
      \"color\": \"$COLOR\",
      \"blocks\": [
        {
          \"type\": \"section\",
          \"text\": {
            \"type\": \"mrkdwn\",
            \"text\": \"$EMOJI *Claude Code - $TITLE*\"
          }
        },
        {
          \"type\": \"context\",
          \"elements\": [
            {
              \"type\": \"mrkdwn\",
              \"text\": \"🕐 $TIMESTAMP | 📁 \`$WORKING_DIR\`\"
            }
          ]
        }
      ]
    }]
  }" "$WEBHOOK_URL"

echo ""
