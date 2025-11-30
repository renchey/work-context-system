#!/bin/bash
# active-window.sh: Detect what window/process has focus right now

set -e

# Detect active window depending on window manager
detect_active_window() {
    local pid=""
    local window_title=""
    local window_name=""

    # Try X11 first (xdotool)
    if command -v xdotool &> /dev/null; then
        local window_id=$(xdotool getactivewindow 2>/dev/null || echo "")
        if [ -n "$window_id" ]; then
            # Get window PID from window ID
            pid=$(xdotool getwindowpid "$window_id" 2>/dev/null || echo "")
            # Get window title
            window_title=$(xdotool getwindowname "$window_id" 2>/dev/null || echo "")
            # Get window class (process name)
            window_name=$(xdotool getwindowname "$window_id" 2>/dev/null | cut -d' ' -f1 || echo "")
        fi
    fi

    # Fallback: wmctrl for X11
    if [ -z "$pid" ] && command -v wmctrl &> /dev/null; then
        local active_window=$(wmctrl -l | grep '\*' | awk '{print $1}')
        if [ -n "$active_window" ]; then
            window_title=$(wmctrl -l | grep '\*' | cut -d' ' -f5- || echo "")
        fi
    fi

    # Last resort: Check foreground process from shell
    if [ -z "$pid" ]; then
        pid=$(ps -o ppid= -p $$ 2>/dev/null | awk '{print $1}')
    fi

    echo "$pid" "$window_title"
}

# Get process name from PID
get_process_name() {
    local pid=$1
    if [ -z "$pid" ] || [ "$pid" = "0" ]; then
        echo "unknown"
        return
    fi

    # Try /proc first (Linux)
    if [ -r "/proc/$pid/comm" ]; then
        cat "/proc/$pid/comm"
        return
    fi

    # Fallback: ps
    ps -p "$pid" -o comm= 2>/dev/null || echo "unknown"
}

# Get working directory of process
get_process_cwd() {
    local pid=$1
    if [ -z "$pid" ] || [ "$pid" = "0" ]; then
        echo "$HOME"
        return
    fi

    # Try /proc first (Linux)
    if [ -L "/proc/$pid/cwd" ]; then
        readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "$HOME"
        return
    fi

    # Fallback: can't determine
    echo "$HOME"
}

# Get command line of process
get_process_cmdline() {
    local pid=$1
    if [ -z "$pid" ] || [ "$pid" = "0" ]; then
        echo ""
        return
    fi

    if [ -r "/proc/$pid/cmdline" ]; then
        tr '\0' ' ' < "/proc/$pid/cmdline" | xargs echo
        return
    fi

    ps -p "$pid" -o args= 2>/dev/null || echo ""
}

# Main detection
read -r pid window_title <<< "$(detect_active_window)"

process_name=$(get_process_name "$pid")
process_cwd=$(get_process_cwd "$pid")
process_cmdline=$(get_process_cmdline "$pid")

# Output as JSON
jq -n \
    --arg pid "$pid" \
    --arg process_name "$process_name" \
    --arg window_title "$window_title" \
    --arg process_cwd "$process_cwd" \
    --arg process_cmdline "$process_cmdline" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    '{
        pid: ($pid | tonumber? // null),
        process_name: $process_name,
        window_title: $window_title,
        process_cwd: $process_cwd,
        process_cmdline: $process_cmdline,
        timestamp: $timestamp
    }'
