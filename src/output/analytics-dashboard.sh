#!/usr/bin/env bash
# analytics-dashboard.sh: Display comprehensive analytics dashboard with ASCII charts

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"
STATE_FILE="${HOME}/.claude-work-data/context-state.json"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session data. Start daemon with: work daemon start"
    exit 1
fi

today=$(date +%Y-%m-%d)

clear

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                     WORK ANALYTICS DASHBOARD                               ║"
echo "║                     $(date '+%A, %B %d, %Y %H:%M')                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# === CURRENT STATUS ===
if [ -f "$STATE_FILE" ]; then
    current_state=$(cat "$STATE_FILE")
    project=$(echo "$current_state" | jq -r '.saved_project // "unknown"')
    worktype=$(echo "$current_state" | jq -r '.data.work_type // "unknown"')
    afk_status=$(echo "$current_state" | jq -r '.afk_status // "unknown"')
    
    echo "┌─ CURRENT CONTEXT ─────────────────────────────────────────────────────────┐"
    printf "│ 📂 %-35s 🎯 %-35s │\n" "Project: $project" "Work: $worktype"
    printf "│ %s %-71s │\n" "$([ "$afk_status" = "active" ] && echo "🟢" || echo "💤")" "Status: $([ "$afk_status" = "active" ] && echo "Active" || echo "Away From Keyboard")"
    echo "└───────────────────────────────────────────────────────────────────────────┘"
    echo ""
fi

# === TODAY'S ACTIVITY CHART ===
echo "┌─ TODAY'S ACTIVITY (Hourly) ───────────────────────────────────────────────┐"
echo "│"

today_data=$(grep "$today" "$SESSION_FILE" 2>/dev/null || true)

if [ -n "$today_data" ]; then
    for hour in $(seq 0 23); do
        hour_str=$(printf "%02d:00" "$hour")
        hour_pattern=$(printf "%02d:" "$hour")
        
        hour_events=$(echo "$today_data" | grep "T${hour_pattern}" | wc -l || echo "0")
        
        bar_len=$((hour_events > 40 ? 40 : hour_events))
        
        if [ "$hour_events" -gt 0 ]; then
            printf "│ %s " "$hour_str"
            printf '█%.0s' $(seq 1 "$bar_len")
            printf " %d\n" "$hour_events"
        fi
    done
else
    echo "│   No activity recorded for today yet."
fi

echo "│"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

# === 7-DAY CONTEXT SWITCHES ===
echo "┌─ 7-DAY CONTEXT SWITCHES ──────────────────────────────────────────────────┐"
echo "│"

for i in $(seq 6 -1 0); do
    day_date=$(date -d "$today - $i days" +%Y-%m-%d 2>/dev/null || date -v-${i}d -j -f "%Y-%m-%d" "$today" +%Y-%m-%d)
    day_name=$(date -d "$day_date" +%a 2>/dev/null || date -j -f "%Y-%m-%d" "$day_date" +%a)
    
    day_switches=$(grep "$day_date" "$SESSION_FILE" 2>/dev/null | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "0")
    
    bar_len=$((day_switches > 30 ? 30 : day_switches))
    
    printf "│ %s %s: " "$day_name" "$day_date"
    if [ "$bar_len" -gt 0 ]; then
        printf '▓%.0s' $(seq 1 "$bar_len")
    fi
    printf " %d switches\n" "$day_switches"
done

echo "│"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

# === PROJECT DISTRIBUTION (PIE-LIKE) ===
echo "┌─ PROJECT TIME DISTRIBUTION (Last 7 Days) ─────────────────────────────────┐"
echo "│"

week_start=$(date -d "$today - 7 days" +%Y-%m-%d 2>/dev/null || date -v-7d -j -f "%Y-%m-%d" "$today" +%Y-%m-%d)
week_data=$(grep -E "$week_start|$today" "$SESSION_FILE" 2>/dev/null || true)

if [ -n "$week_data" ]; then
    total_switches=$(echo "$week_data" | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "1")
    
    echo "$week_data" | jq -s '
        [.[] | select(.type == "context_change")] |
        group_by(.data.project) |
        map({
            project: .[0].data.project,
            count: length
        }) |
        sort_by(-.count) |
        .[]
    ' 2>/dev/null | while read -r line; do
        project=$(echo "$line" | jq -r '.project')
        count=$(echo "$line" | jq -r '.count')
        
        if [ "$count" -gt 0 ]; then
            percentage=$(echo "$count $total_switches" | awk '{printf "%.0f", ($1/$2)*100}')
            bar_len=$((percentage / 2))
            if [ "$bar_len" -gt 40 ]; then bar_len=40; fi
            
            printf "│ %-30s " "$project"
            [ "$bar_len" -gt 0 ] && printf '█%.0s' $(seq 1 "$bar_len")
            printf " %d%% (%d)\n" "$percentage" "$count"
        fi
    done
else
    echo "│   No data for the last 7 days."
fi

echo "│"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

# === KEY METRICS ===
today_switches=$(echo "$today_data" | jq -s '[.[] | select(.type == "context_change")] | length' 2>/dev/null || echo "0")
today_afk=$(echo "$today_data" | jq -s '[.[] | select(.type == "afk_detected")] | length' 2>/dev/null || echo "0")
today_projects=$(echo "$today_data" | jq -s '[.[] | select(.type == "context_change") | .data.project] | unique | length' 2>/dev/null || echo "0")

echo "┌─ TODAY'S METRICS ─────────────────────────────────────────────────────────┐"
printf "│ Context Switches: %-20d Projects: %-27d │\n" "$today_switches" "$today_projects"
printf "│ AFK Breaks: %-25d Productivity Score: %-19s │\n" "$today_afk" "$([ "$today_switches" -gt 0 ] && echo "⭐⭐⭐⭐☆" || echo "N/A")"
echo "└───────────────────────────────────────────────────────────────────────────┘"
echo ""

# === INSIGHTS ===
echo "💡 Quick Insights:"
if [ "$today_switches" -gt 20 ]; then
    echo "   ⚠️  High context switching today - consider blocking focus time"
fi
if [ "$today_projects" -gt 5 ]; then
    echo "   ⚠️  Working across many projects - try to batch similar work"
fi
if [ "$today_switches" -lt 5 ] && [ "$today_switches" -gt 0 ]; then
    echo "   ✨ Great focus today - sustained concentration on fewer contexts"
fi
if [ "$today_switches" -eq 0 ]; then
    echo "   ℹ️  No activity detected today yet"
fi

echo ""
echo "Run 'work analytics metrics' for detailed productivity analysis"
echo "Run 'work analytics burndown' for weekly progress tracking"
echo ""
