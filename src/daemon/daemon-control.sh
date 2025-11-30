#!/usr/bin/env bash
# daemon-control.sh: Control the context daemon (start/stop/status)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DAEMON_PID_FILE="${HOME}/.claude-work-data/daemon.pid"
DAEMON_LOG="${HOME}/.claude-work-data/daemon.log"

mkdir -p "$(dirname "$DAEMON_PID_FILE")"

start_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local old_pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo "✓ Daemon already running (PID: $old_pid)"
            return 0
        fi
    fi
    
    # Start daemon in background, detached from terminal
    nohup "$PROJECT_DIR/src/daemon/context-daemon.sh" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$DAEMON_PID_FILE"
    echo "✓ Daemon started (PID: $pid)"
}

stop_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$DAEMON_PID_FILE"
            echo "✓ Daemon stopped (was PID: $pid)"
        else
            echo "✗ Daemon not running (stale PID file)"
            rm -f "$DAEMON_PID_FILE"
        fi
    else
        echo "✗ Daemon not running"
    fi
}

status_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✓ Daemon running (PID: $pid)"
            echo ""
            echo "Recent log entries:"
            tail -5 "$DAEMON_LOG" 2>/dev/null || echo "(No log entries)"
            return 0
        else
            echo "✗ Daemon not running (stale PID file)"
            rm -f "$DAEMON_PID_FILE"
            return 1
        fi
    else
        echo "✗ Daemon not running"
        return 1
    fi
}

case "${1:-status}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    logs)
        tail -f "$DAEMON_LOG"
        ;;
    *)
        echo "Usage: daemon-control.sh {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
