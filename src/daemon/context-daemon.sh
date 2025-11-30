#!/usr/bin/env bash
# context-daemon.sh: Core daemon for continuous context tracking

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_FILE="${HOME}/.claude-work-data/sessions.jsonl"
STATE_FILE="${HOME}/.claude-work-data/context-state.json"
DAEMON_LOG="${HOME}/.claude-work-data/daemon.log"
POLL_INTERVAL=30  # seconds
AFK_THRESHOLD=900  # 15 minutes in seconds

mkdir -p "$(dirname "$SESSION_FILE")" "$(dirname "$STATE_FILE")"

log_event() {
    local event_type=$1
    local data=$2
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    jq -n \
        --arg type "$event_type" \
        --arg timestamp "$timestamp" \
        --argjson data "$data" \
        '{type: $type, timestamp: $timestamp, data: $data}' >> "$SESSION_FILE"
}

get_last_activity() {
    # Get timestamp of last shell command
    stat -c %Y ~/.bash_history 2>/dev/null || date +%s
}

check_afk_status() {
    local last_activity=$(get_last_activity)
    local now=$(date +%s)
    local idle_seconds=$((now - last_activity))
    
    if [ $idle_seconds -gt $AFK_THRESHOLD ]; then
        echo "afk"
    else
        echo "active"
    fi
}

run_detectors() {
    # Run all detectors
    local active_window=$("$PROJECT_DIR/src/detectors/active-window.sh" 2>/dev/null || echo "{}")
    local process_tree=$("$PROJECT_DIR/src/detectors/process-tree.sh" 2>/dev/null || echo "{}")
    local file_descriptors=$("$PROJECT_DIR/src/detectors/file-descriptors.sh" 2>/dev/null || echo "{}")
    
    # Run inference
    echo "$active_window" | "$PROJECT_DIR/src/inference-combined.sh" 2>/dev/null || echo "{}"
}

daemon_loop() {
    local last_context=""
    local last_afk_status=""
    local last_process_count=0
    
    echo "[$(date)] Daemon started (PID: $$)" >> "$DAEMON_LOG"
    
    while true; do
        # Run detection
        local current_state=$(run_detectors)
        local current_context=$(echo "$current_state" | jq -r '.project // "unknown"')
        local current_afk=$(check_afk_status)
        
        # Get process count
        local process_count=$(pgrep -c '.' 2>/dev/null || echo "0")
        
        # Log context change
        if [ "$last_context" != "$current_context" ]; then
            log_event "context_change" "{\"project\": \"$current_context\", \"state\": $current_state}"
            last_context="$current_context"
        fi
        
        # Log AFK change
        if [ "$last_afk_status" != "$current_afk" ]; then
            if [ "$current_afk" = "afk" ]; then
                local idle_min=$(( ($(date +%s) - $(get_last_activity)) / 60 ))
                log_event "afk_detected" "{\"idle_minutes\": $idle_min}"
            else
                log_event "back_active" "{\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
            fi
            last_afk_status="$current_afk"
        fi
        
        # Log background work changes
        if [ $process_count -gt $last_process_count ]; then
            log_event "background_work" "{\"process_count\": $process_count, \"change\": \"increase\"}"
        elif [ $process_count -lt $last_process_count ]; then
            log_event "background_work" "{\"process_count\": $process_count, \"change\": \"decrease\"}"
        fi
        last_process_count=$process_count
        
        # Save current state
        echo "$current_state" | jq \
            --arg project "$current_context" \
            --arg afk_status "$current_afk" \
            --arg process_count "$process_count" \
            '. + {
                saved_project: $project,
                afk_status: $afk_status,
                background_process_count: ($process_count | tonumber)
            }' > "$STATE_FILE" 2>/dev/null || true
        
        # Sleep before next poll
        sleep "$POLL_INTERVAL"
    done
}

# Trap signals for graceful shutdown
trap 'echo "[$(date)] Daemon shutting down (PID: $$)" >> "$DAEMON_LOG"; exit 0' SIGTERM SIGINT

# Start daemon
daemon_loop
