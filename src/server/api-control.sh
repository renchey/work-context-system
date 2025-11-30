#!/usr/bin/env bash
# API daemon control script

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_SCRIPT="$PROJECT_DIR/src/server/api.js"
PID_FILE="${HOME}/.claude-work-data/api.pid"
LOG_FILE="${HOME}/.claude-work-data/api.log"

start_api() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✓ API already running (PID $(cat "$PID_FILE"))"
        echo "  Dashboard: http://localhost:3042/dashboard.html"
        return 0
    fi
    
    echo "Starting Work Context API..."
    
    mkdir -p "$(dirname "$PID_FILE")"
    
    nohup node "$API_SCRIPT" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    
    sleep 2
    
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✓ API started (PID $(cat "$PID_FILE"))"
        echo "  Dashboard: http://localhost:3042/dashboard.html"
        echo "  API: http://localhost:3042/api/status"
        echo "  Logs: $LOG_FILE"
    else
        echo "✗ Failed to start API"
        rm -f "$PID_FILE"
        tail -20 "$LOG_FILE"
        exit 1
    fi
}

stop_api() {
    if [ ! -f "$PID_FILE" ]; then
        echo "API not running (no PID file)"
        return 0
    fi
    
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo "Stopping API (PID $pid)..."
        kill "$pid"
        sleep 1
        
        if kill -0 "$pid" 2>/dev/null; then
            echo "Force killing API..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        echo "✓ API stopped"
    else
        echo "API not running (stale PID file)"
    fi
    
    rm -f "$PID_FILE"
}

status_api() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        pid=$(cat "$PID_FILE")
        echo "✓ API running (PID $pid)"
        echo "  Dashboard: http://localhost:3042/dashboard.html"
        echo "  Uptime: $(ps -p "$pid" -o etime= | xargs)"
        echo ""
        echo "Recent logs:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No logs yet"
    else
        echo "✗ API not running"
        if [ -f "$PID_FILE" ]; then
            rm -f "$PID_FILE"
        fi
    fi
}

logs_api() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "No log file found"
        exit 1
    fi
    
    echo "Following API logs (Ctrl+C to stop)..."
    tail -f "$LOG_FILE"
}

case "${1:-status}" in
    start)
        start_api
        ;;
    stop)
        stop_api
        ;;
    restart)
        stop_api
        sleep 1
        start_api
        ;;
    status)
        status_api
        ;;
    logs)
        logs_api
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
