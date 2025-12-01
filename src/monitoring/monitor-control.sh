#!/usr/bin/env bash
# monitor-control.sh: Control monitoring services

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR="${HOME}/.claude-work-data"
MONITOR_PID_FILE="$DATA_DIR/monitor.pid"
HEALTH_SCRIPT="$PROJECT_DIR/src/monitoring/health-check.sh"
METRICS_SCRIPT="$PROJECT_DIR/src/monitoring/metrics-export.sh"

start_monitor() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local pid=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Monitor already running (PID: $pid)"
            return 1
        fi
    fi
    
    # Start health check in watch mode
    nohup bash "$HEALTH_SCRIPT" --watch > "$DATA_DIR/monitor.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$MONITOR_PID_FILE"
    
    echo "✓ Monitor started (PID: $pid)"
    echo "  - Health checks running every 10s"
    echo "  - Log: $DATA_DIR/monitor.log"
    echo "  - Use 'work monitor status' to check"
}

stop_monitor() {
    if [ ! -f "$MONITOR_PID_FILE" ]; then
        echo "Monitor not running"
        return 0
    fi
    
    local pid=$(cat "$MONITOR_PID_FILE")
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Monitor not running (stale PID file)"
        rm -f "$MONITOR_PID_FILE"
        return 0
    fi
    
    echo "Stopping monitor (PID: $pid)..."
    kill "$pid" 2>/dev/null || true
    
    # Wait for graceful shutdown
    for i in {1..10}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi
        sleep 0.5
    done
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
    fi
    
    rm -f "$MONITOR_PID_FILE"
    echo "✓ Monitor stopped"
}

status_monitor() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local pid=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Monitor Status: ✓ RUNNING (PID: $pid)"
            echo ""
            
            # Show recent health log
            if [ -f "$DATA_DIR/health.log" ]; then
                echo "Recent Health Events:"
                tail -10 "$DATA_DIR/health.log"
            fi
            return 0
        else
            echo "Monitor Status: ✗ NOT RUNNING (stale PID)"
            return 1
        fi
    else
        echo "Monitor Status: ✗ NOT RUNNING"
        return 1
    fi
}

health_check() {
    bash "$HEALTH_SCRIPT"
}

logs_monitor() {
    if [ -f "$DATA_DIR/monitor.log" ]; then
        tail -f "$DATA_DIR/monitor.log"
    else
        echo "No monitor log found"
        exit 1
    fi
}

metrics_command() {
    local action="${1:-print}"
    shift || true
    bash "$METRICS_SCRIPT" "$action" "$@"
}

# Main command routing
case "${1:-status}" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    restart)
        stop_monitor
        sleep 1
        start_monitor
        ;;
    status)
        status_monitor
        ;;
    health)
        health_check
        ;;
    logs)
        logs_monitor
        ;;
    metrics)
        shift || true
        metrics_command "$@"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|health|logs|metrics}"
        echo ""
        echo "Commands:"
        echo "  start          - Start monitoring service"
        echo "  stop           - Stop monitoring service"
        echo "  restart        - Restart monitoring service"
        echo "  status         - Show monitor status + recent events"
        echo "  health         - Run health check once"
        echo "  logs           - Tail monitor logs"
        echo "  metrics [cmd]  - Manage Prometheus metrics"
        echo ""
        echo "Metrics commands:"
        echo "  metrics generate      - Generate metrics file"
        echo "  metrics print         - Print metrics to stdout"
        echo "  metrics serve [port]  - Serve metrics via HTTP"
        echo "  metrics watch         - Watch metrics in real-time"
        exit 1
        ;;
esac
