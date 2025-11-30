#!/usr/bin/env bash
# slack-status-sync.sh: Auto-update Slack status based on work context

set -euo pipefail

STATE_FILE="${HOME}/.claude-work-data/context-state.json"
SLACK_TOKEN="${SLACK_BOT_TOKEN:-}"

if [ -z "$SLACK_TOKEN" ]; then
    echo "Error: SLACK_BOT_TOKEN not set"
    exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
    echo "No state file. Start daemon first: work daemon start"
    exit 1
fi

# Get current work context
project=$(jq -r '.saved_project // "unknown"' "$STATE_FILE")
worktype=$(jq -r '.data.work_type // "unknown"' "$STATE_FILE")
afk_status=$(jq -r '.afk_status // "unknown"' "$STATE_FILE")
confidence=$(jq -r '.data.overall_confidence // 0' "$STATE_FILE" | awk '{printf "%.0f", $1*100}')

# Build Slack status
if [ "$afk_status" = "afk" ]; then
    status_emoji=":zzz:"
    status_text="Away - ${confidence}% confident"
else
    case "$worktype" in
        code-review) status_emoji=":eyes:" ;;
        development) status_emoji=":keyboard:" ;;
        testing) status_emoji=":test_tube:" ;;
        ops-deployment) status_emoji=":rocket:" ;;
        communication) status_emoji=":speech_balloon:" ;;
        documentation) status_emoji=":memo:" ;;
        research) status_emoji=":mag:" ;;
        debugging) status_emoji=":bug:" ;;
        *) status_emoji=":computer:" ;;
    esac
    status_text="${project} • ${worktype} (${confidence}%)"
fi

# Call Slack API
curl -s -X POST https://slack.com/api/users.profile.set \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"profile\": {
            \"status_emoji\": \"$status_emoji\",
            \"status_text\": \"$status_text\"
        }
    }" > /dev/null

echo "✓ Slack status updated: $status_text"
