#!/usr/bin/env bash
# work-analyze.sh: Analyze work patterns and time allocation

set -euo pipefail

SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No data. Start daemon with: work daemon start"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  WORK ANALYTICS                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 OVERVIEW"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total_events=$(wc -l < "$SESSION_FILE")
context_changes=$(grep -c '"context_change"' "$SESSION_FILE" || echo 0)
afk_periods=$(grep -c '"afk_detected"' "$SESSION_FILE" || echo 0)
bg_changes=$(grep -c '"background_work"' "$SESSION_FILE" || echo 0)

echo "  Total events logged: $total_events"
echo "  Context switches: $context_changes"
echo "  AFK periods detected: $afk_periods"
echo "  Background process changes: $bg_changes"
echo ""

echo "📂 PROJECTS WORKED ON"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep '"context_change"' "$SESSION_FILE" 2>/dev/null | \
    jq -r '.data.project' | \
    sort | uniq -c | sort -rn | \
    awk '{printf "  %-20s %3d switches\n", $2, $1}'
echo ""

echo "⏱️  AFK ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $afk_periods -gt 0 ]; then
    total_afk=$(grep '"afk_detected"' "$SESSION_FILE" 2>/dev/null | \
        jq -r '.data.idle_minutes' | \
        awk '{sum+=$1} END {print sum}')
    avg_afk=$((total_afk / afk_periods))
    echo "  Total AFK time: ~${total_afk} minutes"
    echo "  Average AFK period: ~${avg_afk} minutes"
    echo "  AFK events: $afk_periods"
else
    echo "  No AFK periods detected"
fi
echo ""

echo "🎯 WORK TYPES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep '"context_change"' "$SESSION_FILE" 2>/dev/null | \
    jq -r '.data.work_type' | \
    sort | uniq -c | sort -rn | \
    awk '{printf "  %-20s %3d times\n", $2, $1}'
echo ""

echo "⏰ TIMELINE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  First activity: $(head -1 "$SESSION_FILE" | jq -r '.timestamp')"
echo "  Last activity: $(tail -1 "$SESSION_FILE" | jq -r '.timestamp')"
echo ""
