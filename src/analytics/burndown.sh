#!/usr/bin/env bash
# burndown.sh: Sprint/weekly progress tracking based on work context data

set -euo pipefail

SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session data. Start daemon with: work daemon start"
    exit 1
fi

period="${1:-week}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PROGRESS BURNDOWN ($period)                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Calculate date range
case "$period" in
    week)
        days=7
        start_date=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
        ;;
    sprint)
        days=14
        start_date=$(date -d "14 days ago" +%Y-%m-%d 2>/dev/null || date -v-14d +%Y-%m-%d)
        ;;
    month)
        days=30
        start_date=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
        ;;
    *)
        echo "Usage: burndown.sh [week|sprint|month]"
        exit 1
        ;;
esac

echo "  📅 Period: $(date -d "$start_date" +"%b %d" 2>/dev/null || date -j -f "%Y-%m-%d" "$start_date" +"%b %d") - $(date +"%b %d")"
echo ""

# Daily work hours
echo "  ⏱️  Daily Active Hours"
echo ""
for i in $(seq 0 $((days - 1))); do
    day_date=$(date -d "$start_date + $i days" +%Y-%m-%d 2>/dev/null || date -v+${i}d -j -f "%Y-%m-%d" "$start_date" +%Y-%m-%d)
    day_name=$(date -d "$day_date" +%a 2>/dev/null || date -j -f "%Y-%m-%d" "$day_date" +%a)
    
    day_data=$(grep "$day_date" "$SESSION_FILE" 2>/dev/null || true)
    
    if [ -z "$day_data" ]; then
        hours=0
    else
        hours=$(echo "$day_data" | jq -s '
            if length > 0 then
                [.[] | select(.type == "context_change" or .type == "back_active")] |
                if length > 1 then
                    (.[length-1].timestamp | fromdateiso8601) - (.[0].timestamp | fromdateiso8601) | . / 3600
                else
                    0
                end
            else
                0
            end
        ' 2>/dev/null || echo "0")
    fi
    
    # Ensure hours is valid
    if [ -z "$hours" ] || [ "$hours" = "null" ]; then
        hours=0
    fi
    
    # Format and display
    hours_int=$(echo "$hours" | awk '{printf "%.1f", $1}')
    bar_len=$(echo "$hours" | awk '{printf "%.0f", $1 * 2}')
    if [ "$bar_len" -gt 20 ]; then bar_len=20; fi
    
    printf "     %s %s: " "$day_name" "$day_date"
    if [ "$bar_len" -gt 0 ]; then
        printf '█%.0s' $(seq 1 "$bar_len")
    fi
    printf " ${hours_int}h\n"
done
echo ""

# Project time distribution
echo "  📂 Time by Project"
echo ""
all_data=$(grep -E "$start_date" "$SESSION_FILE" 2>/dev/null || true)

if [ -n "$all_data" ]; then
    echo "$all_data" | jq -s '
        [.[] | select(.type == "context_change")] |
        group_by(.data.project) |
        map({
            project: .[0].data.project,
            switches: length
        }) |
        sort_by(-.switches) |
        .[]
    ' 2>/dev/null | while read -r line; do
        project=$(echo "$line" | jq -r '.project')
        switches=$(echo "$line" | jq -r '.switches')
        
        if [ "$switches" -gt 0 ]; then
            bar_len=$((switches > 20 ? 20 : switches))
            printf "     %-25s " "$project"
            printf '▓%.0s' $(seq 1 "$bar_len")
            printf " %d sessions\n" "$switches"
        fi
    done
fi
echo ""

# Weekly summary
total_switches=$(echo "$all_data" | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "0")
total_afk=$(echo "$all_data" | jq -s '[.[] | select(.type == "afk_detected")] | length' 2>/dev/null || echo "0")
unique_projects=$(echo "$all_data" | jq -s '[.[] | select(.type == "context_change") | .data.project] | unique | length' 2>/dev/null || echo "0")

echo "  📊 Period Summary"
echo "     Total context switches: $total_switches"
echo "     Unique projects: $unique_projects"
echo "     AFK breaks: $total_afk"
echo ""

# Trend indicator
recent_half=$(echo "$all_data" | tail -n $(($(echo "$all_data" | wc -l) / 2)) | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "0")
earlier_half=$(echo "$all_data" | head -n $(($(echo "$all_data" | wc -l) / 2)) | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "0")

if [ "$recent_half" -gt "$earlier_half" ]; then
    trend="📈 Increasing activity"
elif [ "$recent_half" -lt "$earlier_half" ]; then
    trend="📉 Decreasing activity"
else
    trend="➡️  Stable activity"
fi

echo "  📈 Trend: $trend"
echo ""
