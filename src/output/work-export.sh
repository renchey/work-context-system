#!/usr/bin/env bash
# work-export.sh: Export work data in various formats

set -euo pipefail

SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"
format="${1:-json}"
output="${2:-}"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No data to export"
    exit 1
fi

case "$format" in
    json)
        # Pretty-printed JSON
        jq -s '.' "$SESSION_FILE" | if [ -n "$output" ]; then
            tee "$output"
        else
            cat
        fi
        ;;
    csv)
        # Export as CSV
        {
            echo "timestamp,type,project,worktype,idle_minutes"
            jq -r '.[] | [.timestamp, .type, .data.project // "", .data.work_type // "", .data.idle_minutes // ""] | @csv' "$SESSION_FILE"
        } | if [ -n "$output" ]; then
            tee "$output"
        else
            cat
        fi
        ;;
    ndjson)
        # Already in ndjson format
        cat "$SESSION_FILE" | if [ -n "$output" ]; then
            tee "$output"
        else
            cat
        fi
        ;;
    summary)
        # Text summary
        {
            echo "Work Context Export - $(date)"
            echo ""
            echo "Total Events: $(wc -l < "$SESSION_FILE")"
            echo "Context Changes: $(grep -c '"context_change"' "$SESSION_FILE" || echo 0)"
            echo "AFK Periods: $(grep -c '"afk_detected"' "$SESSION_FILE" || echo 0)"
            echo ""
            echo "Projects:"
            jq -r '.[] | select(.type == "context_change") | .data.project' "$SESSION_FILE" | \
                sort | uniq -c | sort -rn
        } | if [ -n "$output" ]; then
            tee "$output"
        else
            cat
        fi
        ;;
    *)
        echo "Usage: work-export [json|csv|ndjson|summary] [output-file]"
        exit 1
        ;;
esac

[ -n "$output" ] && echo "✓ Exported to $output"
