#!/usr/bin/env bash
# work-status-now.sh: Show current work context in real-time

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="${HOME}/.claude-work-data/context-state.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "Daemon not running or no state yet. Start with: daemon-control.sh start"
    exit 1
fi

current_state=$(cat "$STATE_FILE")
project=$(echo "$current_state" | jq -r '.saved_project // "unknown"')
worktype=$(echo "$current_state" | jq -r '.data.work_type // "unknown"')
afk_status=$(echo "$current_state" | jq -r '.afk_status // "unknown"')
process_count=$(echo "$current_state" | jq -r '.background_process_count // 0')
confidence=$(echo "$current_state" | jq -r '.data.overall_confidence // 0' | awk '{printf "%.0f", $1*100}')

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  WORK STATUS (Real-Time)                                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  📂 Project: $project"
echo "  🎯 Work Type: $worktype"
echo "  🔒 Confidence: ${confidence}%"
echo "  📊 Status: $([ "$afk_status" = "active" ] && echo "🟢 Active" || echo "💤 AFK")"
echo "  🐳 Background Processes: $process_count"
echo ""

if [ $process_count -gt 0 ]; then
    echo "  ⚠️  Cognitive load: $(printf '▓%.0s' $(seq 1 $((process_count > 9 ? 9 : process_count))))"
    [ $process_count -gt 5 ] && echo "      ⚠️  HIGH LOAD - Consider pausing new work"
fi

echo ""
