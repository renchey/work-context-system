#!/usr/bin/env bash
# productivity-metrics.sh: Calculate daily context switch rate, focus time ratio, context fragmentation score

set -euo pipefail

SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session data. Start daemon with: work daemon start"
    exit 1
fi

today=$(date +%Y-%m-%d)
time_range="${1:-today}"

case "$time_range" in
    today)
        filter_date="$today"
        ;;
    yesterday)
        filter_date=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
        ;;
    week)
        filter_date=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
        ;;
    *)
        filter_date="$time_range"
        ;;
esac

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PRODUCTIVITY METRICS ($time_range)                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Extract data
if [ "$time_range" = "week" ]; then
    data=$(grep -E "$filter_date|$(date +%Y-%m-%d)" "$SESSION_FILE" 2>/dev/null || true)
else
    data=$(grep "$filter_date" "$SESSION_FILE" 2>/dev/null || true)
fi

if [ -z "$data" ]; then
    echo "  ⚠️  No data for $time_range"
    echo ""
    exit 0
fi

# 1. CONTEXT SWITCH RATE
context_switches=$(echo "$data" | jq -s '[.[] | select(.type == "context_change")] | length')
total_afk_mins=$(echo "$data" | jq -s '[.[] | select(.type == "afk_detected") | .data.idle_minutes // 0] | add // 0')
work_hours=$(echo "$data" | jq -s '
    [.[] | select(.type == "context_change" or .type == "back_active")] |
    if length > 0 then
        (.[length-1].timestamp | fromdateiso8601) - (.[0].timestamp | fromdateiso8601) | . / 3600
    else
        0
    end
' 2>/dev/null || echo "0")

# Ensure work_hours is valid number
if [ -z "$work_hours" ] || [ "$work_hours" = "null" ]; then
    work_hours=0
fi

# Calculate active work hours (excluding AFK time)
active_hours=$(echo "$work_hours $total_afk_mins" | awk '{printf "%.1f", $1 - ($2/60)}')
if (( $(echo "$active_hours < 0" | bc -l 2>/dev/null || echo "1") )); then
    active_hours=0
fi

switch_rate=$(echo "$context_switches $active_hours" | awk '{if ($2>0) printf "%.1f", $1/$2; else print "0"}')

echo "  📊 Context Switch Rate"
echo "     Switches: $context_switches"
echo "     Active hours: $active_hours hrs"
echo "     Rate: $switch_rate switches/hr"
echo ""

# 2. FOCUS TIME RATIO
# Focus time = periods between switches > 30 min without AFK
focus_periods=$(echo "$data" | jq -s '
    [.[] | select(.type == "context_change")] |
    . as $changes |
    [range(0; length - 1)] |
    map($changes[.].timestamp as $start | $changes[. + 1].timestamp as $end |
        {
            duration: (($end | fromdateiso8601) - ($start | fromdateiso8601)) / 60,
            project: $changes[.].data.project
        }
    ) |
    [.[] | select(.duration > 30)] | length
' 2>/dev/null || echo "0")

total_periods=$((context_switches > 0 ? context_switches - 1 : 0))
focus_ratio=$(echo "$focus_periods $total_periods" | awk '{if ($2>0) printf "%.0f", ($1/$2)*100; else print "0"}')

echo "  🎯 Focus Time Ratio"
echo "     Focus periods (>30min): $focus_periods"
echo "     Total periods: $total_periods"
echo "     Ratio: ${focus_ratio}%"
echo ""

# Progress bar
bar_length=$((focus_ratio / 5))
printf "     "
printf '█%.0s' $(seq 1 $bar_length)
printf '░%.0s' $(seq 1 $((20 - bar_length)))
printf " ${focus_ratio}%%\n"
echo ""

# 3. CONTEXT FRAGMENTATION SCORE
# Lower is better: measures how scattered work is across projects
unique_projects=$(echo "$data" | jq -s '[.[] | select(.type == "context_change") | .data.project] | unique | length')
fragmentation=$(echo "$context_switches $unique_projects" | awk '{if ($2>0) printf "%.1f", $1/$2; else print "0"}')

# Interpretation
if (( $(echo "$fragmentation < 2" | bc -l 2>/dev/null || echo "0") )); then
    frag_status="🟢 Excellent - Sustained focus"
elif (( $(echo "$fragmentation < 4" | bc -l 2>/dev/null || echo "0") )); then
    frag_status="🟡 Moderate - Some context bouncing"
else
    frag_status="🔴 High - Frequent task switching"
fi

echo "  🧩 Context Fragmentation Score"
echo "     Unique projects: $unique_projects"
echo "     Switches per project: $fragmentation"
echo "     Status: $frag_status"
echo ""

# 4. SUMMARY INSIGHTS
echo "  💡 Insights"
if (( $(echo "$switch_rate > 5" | bc -l 2>/dev/null || echo "0") )); then
    echo "     ⚠️  High context switch rate - consider blocking focused time"
fi
if (( $(echo "$focus_ratio < 30" | bc -l 2>/dev/null || echo "0") )); then
    echo "     ⚠️  Low focus ratio - aim for longer uninterrupted sessions"
fi
if (( $(echo "$fragmentation > 5" | bc -l 2>/dev/null || echo "0") )); then
    echo "     ⚠️  Highly fragmented work - try batching similar tasks"
fi
if (( $(echo "$switch_rate <= 3" | bc -l 2>/dev/null || echo "1") )) && (( $(echo "$focus_ratio >= 50" | bc -l 2>/dev/null || echo "0") )); then
    echo "     ✨ Great work! You're maintaining good focus"
fi
echo ""
