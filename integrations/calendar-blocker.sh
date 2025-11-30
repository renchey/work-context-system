#!/usr/bin/env bash
# calendar-blocker.sh: Auto-block calendar when high context switching

set -euo pipefail

SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"
GCAL_EMAIL="${GCAL_EMAIL:-}"

if [ -z "$GCAL_EMAIL" ]; then
    echo "Error: GCAL_EMAIL not set"
    exit 1
fi

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session data yet"
    exit 1
fi

# Count context switches in last hour
switches_1h=$(grep "$(date -u -d '1 hour ago' +%Y-%m-%dT%H)" "$SESSION_FILE" | \
    grep '"context_change"' | wc -l)

# Count in last 30 mins
switches_30m=$(grep "$(date -u +%Y-%m-%dT%H:%M)" "$SESSION_FILE" | \
    grep '"context_change"' | wc -l)

echo "Context switches:"
echo "  Last 30 mins: $switches_30m"
echo "  Last 60 mins: $switches_1h"

# If high context switching, block calendar
if [ "$switches_1h" -gt 10 ]; then
    echo ""
    echo "⚠️  High context switching detected!"
    echo "Recommendations:"
    echo "  1. Block calendar for 1 hour (focus time)"
    echo "  2. Close unnecessary applications"
    echo "  3. Reduce background processes"
    echo ""
    echo "To block on Google Calendar:"
    echo "  1. Open Google Calendar"
    echo "  2. Create event: 'Focus Time' for next 1-2 hours"
    echo "  3. Set as 'Busy'"
    echo ""
    
    # Could integrate with gcal API here
    # gcalcli add "Focus Time" -s "$(date)" -e "$(date -d '+1 hour')"
fi

# Show cognitive load
processes=$(jq -r '.background_process_count // 0' "${HOME}/.claude-work-data/context-state.json" 2>/dev/null || echo 0)
echo ""
echo "Current cognitive load: $processes background processes"

if [ "$processes" -gt 5 ]; then
    echo "⚠️  HIGH LOAD - Consider pausing new work"
fi
