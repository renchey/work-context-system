#!/usr/bin/env bash
# metrics-export.sh: Export Prometheus-compatible metrics

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR="${HOME}/.claude-work-data"
DAEMON_PID_FILE="$DATA_DIR/daemon.pid"
API_PID_FILE="$DATA_DIR/api-server.pid"
STATE_FILE="$DATA_DIR/context-state.json"
SESSION_FILE="$DATA_DIR/sessions.jsonl"
METRICS_FILE="$DATA_DIR/metrics.prom"

# Generate Prometheus metrics
generate_metrics() {
    local timestamp=$(date +%s)
    
    # Start metrics file
    cat > "$METRICS_FILE" << 'EOF'
# HELP work_daemon_up Whether the work context daemon is running (1=up, 0=down)
# TYPE work_daemon_up gauge
EOF
    
    # Daemon status
    if [ -f "$DAEMON_PID_FILE" ] && kill -0 "$(cat "$DAEMON_PID_FILE")" 2>/dev/null; then
        echo "work_daemon_up 1" >> "$METRICS_FILE"
    else
        echo "work_daemon_up 0" >> "$METRICS_FILE"
    fi
    
    # API status
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_api_up Whether the API server is running (1=up, 0=down)
# TYPE work_api_up gauge
EOF
    
    if [ -f "$API_PID_FILE" ] && kill -0 "$(cat "$API_PID_FILE")" 2>/dev/null; then
        echo "work_api_up 1" >> "$METRICS_FILE"
    else
        echo "work_api_up 0" >> "$METRICS_FILE"
    fi
    
    # State age
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_state_age_seconds Age of the last state update in seconds
# TYPE work_state_age_seconds gauge
EOF
    
    if [ -f "$STATE_FILE" ]; then
        local state_mtime=$(stat -c %Y "$STATE_FILE")
        local age=$((timestamp - state_mtime))
        echo "work_state_age_seconds $age" >> "$METRICS_FILE"
    else
        echo "work_state_age_seconds -1" >> "$METRICS_FILE"
    fi
    
    # Memory usage (daemon)
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_daemon_memory_bytes Memory usage of the daemon process in bytes
# TYPE work_daemon_memory_bytes gauge
EOF
    
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            local mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo 0)
            local mem_bytes=$((mem_kb * 1024))
            echo "work_daemon_memory_bytes $mem_bytes" >> "$METRICS_FILE"
        else
            echo "work_daemon_memory_bytes 0" >> "$METRICS_FILE"
        fi
    else
        echo "work_daemon_memory_bytes 0" >> "$METRICS_FILE"
    fi
    
    # CPU usage (daemon)
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_daemon_cpu_percent CPU usage percentage of the daemon process
# TYPE work_daemon_cpu_percent gauge
EOF
    
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            local cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null || echo 0)
            echo "work_daemon_cpu_percent $cpu" >> "$METRICS_FILE"
        else
            echo "work_daemon_cpu_percent 0" >> "$METRICS_FILE"
        fi
    else
        echo "work_daemon_cpu_percent 0" >> "$METRICS_FILE"
    fi
    
    # Session log size
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_session_log_bytes Size of the session log file in bytes
# TYPE work_session_log_bytes gauge
EOF
    
    if [ -f "$SESSION_FILE" ]; then
        local size=$(stat -c %s "$SESSION_FILE")
        echo "work_session_log_bytes $size" >> "$METRICS_FILE"
    else
        echo "work_session_log_bytes 0" >> "$METRICS_FILE"
    fi
    
    # Session log entries
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_session_log_entries Total number of entries in the session log
# TYPE work_session_log_entries counter
EOF
    
    if [ -f "$SESSION_FILE" ]; then
        local entries=$(wc -l < "$SESSION_FILE")
        echo "work_session_log_entries $entries" >> "$METRICS_FILE"
    else
        echo "work_session_log_entries 0" >> "$METRICS_FILE"
    fi
    
    # Context switches today
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_context_switches_today Number of context switches today
# TYPE work_context_switches_today counter
EOF
    
    if [ -f "$SESSION_FILE" ]; then
        local today=$(date +%Y-%m-%d)
        local switches=$(grep -c "\"type\":\"context_change\"" "$SESSION_FILE" 2>/dev/null | grep "$today" || echo 0)
        echo "work_context_switches_today $switches" >> "$METRICS_FILE"
    else
        echo "work_context_switches_today 0" >> "$METRICS_FILE"
    fi
    
    # Current project confidence (if available)
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_current_confidence Current project detection confidence (0-100)
# TYPE work_current_confidence gauge
EOF
    
    if [ -f "$STATE_FILE" ]; then
        local confidence=$(jq -r '.confidence // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        echo "work_current_confidence $confidence" >> "$METRICS_FILE"
    else
        echo "work_current_confidence 0" >> "$METRICS_FILE"
    fi
    
    # Disk space available
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_disk_available_bytes Available disk space in data directory in bytes
# TYPE work_disk_available_bytes gauge
EOF
    
    local disk_bytes=$(df -B1 "$DATA_DIR" | awk 'NR==2 {print $4}')
    echo "work_disk_available_bytes $disk_bytes" >> "$METRICS_FILE"
    
    # Process count from state
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_background_processes Number of background processes tracked
# TYPE work_background_processes gauge
EOF
    
    if [ -f "$STATE_FILE" ]; then
        local proc_count=$(jq -r '.background_process_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)
        echo "work_background_processes $proc_count" >> "$METRICS_FILE"
    else
        echo "work_background_processes 0" >> "$METRICS_FILE"
    fi
    
    # AFK status
    cat >> "$METRICS_FILE" << 'EOF'

# HELP work_afk_status Current AFK status (1=afk, 0=active)
# TYPE work_afk_status gauge
EOF
    
    if [ -f "$STATE_FILE" ]; then
        local afk_status=$(jq -r '.afk_status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        if [ "$afk_status" = "afk" ]; then
            echo "work_afk_status 1" >> "$METRICS_FILE"
        else
            echo "work_afk_status 0" >> "$METRICS_FILE"
        fi
    else
        echo "work_afk_status 0" >> "$METRICS_FILE"
    fi
}

# Serve metrics via HTTP (simple mode)
serve_metrics() {
    local port="${1:-9090}"
    
    echo "Starting Prometheus metrics exporter on port $port..."
    echo "Metrics available at: http://localhost:$port/metrics"
    echo "Press Ctrl+C to stop"
    echo ""
    
    while true; do
        generate_metrics
        
        # Simple HTTP server using nc (netcat)
        if command -v nc >/dev/null 2>&1; then
            {
                echo -e "HTTP/1.1 200 OK\r"
                echo -e "Content-Type: text/plain; version=0.0.4\r"
                echo -e "\r"
                cat "$METRICS_FILE"
            } | nc -l -p "$port" -q 1 2>/dev/null || true
        else
            echo "Warning: netcat not available. Generating metrics file only."
            sleep 15
        fi
        
        sleep 5
    done
}

# Main execution
case "${1:-generate}" in
    generate)
        generate_metrics
        echo "Metrics exported to: $METRICS_FILE"
        ;;
    serve)
        serve_metrics "${2:-9090}"
        ;;
    print)
        generate_metrics
        cat "$METRICS_FILE"
        ;;
    watch)
        echo "Watching metrics (Ctrl+C to stop)..."
        echo ""
        while true; do
            clear
            generate_metrics
            cat "$METRICS_FILE"
            sleep 5
        done
        ;;
    *)
        echo "Usage: $0 {generate|serve [port]|print|watch}"
        echo ""
        echo "Commands:"
        echo "  generate       - Generate metrics file"
        echo "  serve [port]   - Serve metrics via HTTP (default port: 9090)"
        echo "  print          - Generate and print metrics to stdout"
        echo "  watch          - Continuously display metrics (updates every 5s)"
        exit 1
        ;;
esac
