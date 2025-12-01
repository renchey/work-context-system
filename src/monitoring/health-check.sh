#!/usr/bin/env bash
# health-check.sh: Monitor daemon health and service status

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR="${HOME}/.claude-work-data"
DAEMON_PID_FILE="$DATA_DIR/daemon.pid"
API_PID_FILE="$DATA_DIR/api-server.pid"
STATE_FILE="$DATA_DIR/context-state.json"
SESSION_FILE="$DATA_DIR/sessions.jsonl"
HEALTH_LOG="$DATA_DIR/health.log"

# Health check thresholds
MAX_STATE_AGE=120  # seconds - state should update every 30s
MAX_MEMORY_MB=150  # MB
MIN_DISK_SPACE_MB=100  # MB

log_health() {
    local status=$1
    local message=$2
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[${timestamp}] ${status}: ${message}" >> "$HEALTH_LOG"
}

check_daemon_running() {
    if [ ! -f "$DAEMON_PID_FILE" ]; then
        echo "DOWN"
        return 1
    fi
    
    local pid=$(cat "$DAEMON_PID_FILE")
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "DOWN"
        return 1
    fi
    
    echo "UP"
    return 0
}

check_api_running() {
    if [ ! -f "$API_PID_FILE" ]; then
        echo "DOWN"
        return 1
    fi
    
    local pid=$(cat "$API_PID_FILE")
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "DOWN"
        return 1
    fi
    
    echo "UP"
    return 0
}

check_state_freshness() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "STALE"
        return 1
    fi
    
    local state_mtime=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local age=$((now - state_mtime))
    
    if [ $age -gt $MAX_STATE_AGE ]; then
        echo "STALE (${age}s old)"
        return 1
    fi
    
    echo "FRESH (${age}s old)"
    return 0
}

check_memory_usage() {
    if [ ! -f "$DAEMON_PID_FILE" ]; then
        echo "N/A"
        return 0
    fi
    
    local pid=$(cat "$DAEMON_PID_FILE")
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "N/A"
        return 0
    fi
    
    # Get RSS in KB and convert to MB
    local mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo 0)
    local mem_mb=$((mem_kb / 1024))
    
    if [ $mem_mb -gt $MAX_MEMORY_MB ]; then
        echo "HIGH (${mem_mb}MB)"
        return 1
    fi
    
    echo "OK (${mem_mb}MB)"
    return 0
}

check_disk_space() {
    local available_mb=$(df -BM "$DATA_DIR" | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [ "$available_mb" -lt $MIN_DISK_SPACE_MB ]; then
        echo "LOW (${available_mb}MB)"
        return 1
    fi
    
    echo "OK (${available_mb}MB available)"
    return 0
}

check_session_log_growth() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo "MISSING"
        return 1
    fi
    
    local line_count=$(wc -l < "$SESSION_FILE" 2>/dev/null || echo 0)
    local size_mb=$(du -m "$SESSION_FILE" | cut -f1)
    
    echo "OK (${line_count} events, ${size_mb}MB)"
    return 0
}

check_api_endpoint() {
    if ! check_api_running > /dev/null 2>&1; then
        echo "SKIP (API not running)"
        return 0
    fi
    
    # Try to query the API
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3042/api/status 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        echo "OK (HTTP 200)"
        return 0
    elif [ "$response" = "000" ]; then
        echo "UNREACHABLE"
        return 1
    else
        echo "ERROR (HTTP ${response})"
        return 1
    fi
}

run_health_check() {
    local exit_code=0
    
    echo "Work Context System - Health Check"
    echo "===================================="
    echo ""
    
    # Check daemon
    echo -n "Daemon Status:      "
    if daemon_status=$(check_daemon_running); then
        echo "✓ $daemon_status"
        log_health "OK" "Daemon running"
    else
        echo "✗ $daemon_status"
        log_health "ERROR" "Daemon not running"
        exit_code=1
    fi
    
    # Check API
    echo -n "API Status:         "
    if api_status=$(check_api_running); then
        echo "✓ $api_status"
        log_health "OK" "API running"
    else
        echo "✗ $api_status"
        log_health "WARN" "API not running"
    fi
    
    # Check state freshness
    echo -n "State Freshness:    "
    if state_status=$(check_state_freshness); then
        echo "✓ $state_status"
        log_health "OK" "State fresh: $state_status"
    else
        echo "✗ $state_status"
        log_health "ERROR" "State stale: $state_status"
        exit_code=1
    fi
    
    # Check memory
    echo -n "Memory Usage:       "
    if mem_status=$(check_memory_usage); then
        echo "✓ $mem_status"
        log_health "OK" "Memory: $mem_status"
    else
        echo "⚠ $mem_status"
        log_health "WARN" "High memory: $mem_status"
    fi
    
    # Check disk
    echo -n "Disk Space:         "
    if disk_status=$(check_disk_space); then
        echo "✓ $disk_status"
        log_health "OK" "Disk: $disk_status"
    else
        echo "⚠ $disk_status"
        log_health "WARN" "Low disk: $disk_status"
    fi
    
    # Check session log
    echo -n "Session Log:        "
    if session_status=$(check_session_log_growth); then
        echo "✓ $session_status"
        log_health "OK" "Session log: $session_status"
    else
        echo "✗ $session_status"
        log_health "ERROR" "Session log: $session_status"
        exit_code=1
    fi
    
    # Check API endpoint
    echo -n "API Endpoint:       "
    if api_endpoint_status=$(check_api_endpoint); then
        echo "✓ $api_endpoint_status"
        log_health "OK" "API endpoint: $api_endpoint_status"
    else
        echo "✗ $api_endpoint_status"
        log_health "ERROR" "API endpoint: $api_endpoint_status"
    fi
    
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        echo "Overall Status: ✓ HEALTHY"
        log_health "OK" "System healthy"
    else
        echo "Overall Status: ✗ UNHEALTHY"
        log_health "ERROR" "System unhealthy"
    fi
    
    return $exit_code
}

# Support watch mode
if [ "${1:-}" = "--watch" ] || [ "${1:-}" = "-w" ]; then
    echo "Starting health monitoring (Ctrl+C to stop)..."
    echo ""
    while true; do
        clear
        run_health_check
        sleep 10
    done
else
    run_health_check
fi
