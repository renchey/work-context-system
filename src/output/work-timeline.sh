#!/usr/bin/env bash
# work-timeline.sh: Show timeline of context switches throughout day

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session data. Run daemon to collect data."
    exit 1
fi

timeline_range="${1:-today}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  WORK TIMELINE ($timeline_range)                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Filter by date if requested
if [ "$timeline_range" = "today" ]; then
    today=$(date +%Y-%m-%d)
    grep "$today" "$SESSION_FILE" | while read -r line; do
        event_type=$(echo "$line" | jq -r '.type')
        timestamp=$(echo "$line" | jq -r '.timestamp')
        time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'Z' -f1)
        
        case "$event_type" in
            context_change)
                project=$(echo "$line" | jq -r '.data.project')
                echo "  ⏰ $time → 📂 Context changed to: $project"
                ;;
            afk_detected)
                idle_mins=$(echo "$line" | jq -r '.data.idle_minutes')
                echo "  ⏰ $time → 💤 AFK detected ($idle_mins min)"
                ;;
            back_active)
                echo "  ⏰ $time → 🟢 Back active"
                ;;
            background_work)
                count=$(echo "$line" | jq -r '.data.process_count')
                change=$(echo "$line" | jq -r '.data.change')
                echo "  ⏰ $time → 🐳 Background work: $count processes ($change)"
                ;;
        esac
    done
else
    # Show all entries
    jq -r '.timestamp + " | " + .type' "$SESSION_FILE" | tail -20
fi

echo ""
