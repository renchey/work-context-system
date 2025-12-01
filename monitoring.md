# Work Context System - Monitoring & Observability

Built-in monitoring and observability for the Work Context System daemon and API services.

## Overview

The monitoring system provides:
- **Health Checks**: Continuous daemon and API health monitoring
- **Prometheus Metrics**: Standard metrics export for monitoring tools
- **Service Monitoring**: systemd service for automated health checks
- **Alerting**: Health log tracking for anomaly detection

## Quick Start

### Start Monitoring

```bash
# Start the monitoring service
work monitor start

# Check monitor status
work monitor status

# Run a one-time health check
work monitor health
```

### View Health Status

```bash
# Show current health status
work monitor health

# Watch health status in real-time (updates every 10s)
src/monitoring/health-check.sh --watch

# View health event logs
tail -f ~/.claude-work-data/health.log
```

### Prometheus Metrics

```bash
# Generate metrics file
work monitor metrics generate

# Print metrics to stdout
work monitor metrics print

# Serve metrics via HTTP (default port 9090)
work monitor metrics serve 9090

# Watch metrics in real-time
work monitor metrics watch
```

## Health Checks

The health check system monitors:

### 1. Daemon Status
- **Check**: Is the context tracking daemon running?
- **Status**: UP/DOWN
- **Alert**: Critical if daemon is down

### 2. API Status
- **Check**: Is the API server running?
- **Status**: UP/DOWN
- **Alert**: Warning if API is down (non-critical)

### 3. State Freshness
- **Check**: Is the context state file being updated?
- **Threshold**: State must be updated within 120 seconds (30s poll + buffer)
- **Alert**: Critical if state is stale

### 4. Memory Usage
- **Check**: Daemon memory consumption
- **Threshold**: < 150 MB
- **Alert**: Warning if memory usage is high

### 5. Disk Space
- **Check**: Available disk space in data directory
- **Threshold**: > 100 MB available
- **Alert**: Warning if disk space is low

### 6. Session Log
- **Check**: Session log file exists and is growing
- **Metrics**: Event count and file size
- **Alert**: Critical if session log is missing

### 7. API Endpoint
- **Check**: API responds to HTTP requests
- **Test**: HTTP GET to http://localhost:3042/api/status
- **Alert**: Error if API is unreachable or returns non-200 status

## Health Check Output

```
Work Context System - Health Check
====================================

Daemon Status:      ✓ UP
API Status:         ✓ UP
State Freshness:    ✓ FRESH (28s old)
Memory Usage:       ✓ OK (45MB)
Disk Space:         ✓ OK (15234MB available)
Session Log:        ✓ OK (1247 events, 2MB)
API Endpoint:       ✓ OK (HTTP 200)

Overall Status: ✓ HEALTHY
```

## Prometheus Metrics

The following metrics are exported in Prometheus format:

### Service Status Metrics

```prometheus
# Daemon running status (1=up, 0=down)
work_daemon_up 1

# API server running status (1=up, 0=down)
work_api_up 1
```

### Performance Metrics

```prometheus
# Age of last state update in seconds
work_state_age_seconds 28

# Daemon memory usage in bytes
work_daemon_memory_bytes 47185920

# Daemon CPU usage percentage
work_daemon_cpu_percent 0.5
```

### Data Metrics

```prometheus
# Session log file size in bytes
work_session_log_bytes 2048576

# Total session log entries
work_session_log_entries 1247

# Context switches today
work_context_switches_today 42

# Background processes tracked
work_background_processes 156
```

### Context Metrics

```prometheus
# Current project detection confidence (0-100)
work_current_confidence 95

# AFK status (1=afk, 0=active)
work_afk_status 0

# Available disk space in bytes
work_disk_available_bytes 15976300544
```

## Integration with Prometheus

### 1. Serve Metrics Endpoint

```bash
# Start metrics HTTP server
work monitor metrics serve 9090
```

### 2. Configure Prometheus

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'work-context-system'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s
    scrape_timeout: 10s
```

### 3. Example PromQL Queries

```promql
# Daemon uptime
work_daemon_up

# Average memory usage over 5 minutes
avg_over_time(work_daemon_memory_bytes[5m])

# Context switch rate (per hour)
rate(work_session_log_entries[1h]) * 3600

# Alert when daemon is down
work_daemon_up == 0

# Alert when state is stale (> 2 minutes old)
work_state_age_seconds > 120
```

## Systemd Service

### Installation

```bash
# Copy service file
sudo cp systemd/work-monitor.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable work-monitor.service

# Start service
sudo systemctl start work-monitor.service
```

### Management

```bash
# Check service status
sudo systemctl status work-monitor.service

# View service logs
sudo journalctl -u work-monitor.service -f

# Restart service
sudo systemctl restart work-monitor.service

# Stop service
sudo systemctl stop work-monitor.service
```

## Monitoring Service Details

### Service Configuration

- **Type**: Forking (background daemon)
- **User**: renchey (non-root)
- **Memory Limit**: 50MB
- **CPU Quota**: 2%
- **Restart Policy**: on-failure
- **Restart Delay**: 10 seconds

### Health Check Interval

The monitoring service runs health checks every **10 seconds** and logs events to:
- `~/.claude-work-data/health.log` - Structured health event log
- `~/.claude-work-data/monitor.log` - Full monitor output

## Command Reference

### Monitor Service Commands

```bash
work monitor start        # Start monitoring service
work monitor stop         # Stop monitoring service
work monitor restart      # Restart monitoring service
work monitor status       # Show status + recent events
work monitor health       # Run health check once
work monitor logs         # Tail monitor logs
```

### Metrics Commands

```bash
work monitor metrics generate      # Generate metrics file
work monitor metrics print         # Print metrics to stdout
work monitor metrics serve [port]  # Serve via HTTP
work monitor metrics watch         # Watch in real-time
```

### Direct Script Usage

```bash
# Health check script
src/monitoring/health-check.sh           # Run once
src/monitoring/health-check.sh --watch   # Continuous mode

# Metrics export script
src/monitoring/metrics-export.sh generate    # Generate file
src/monitoring/metrics-export.sh print       # Print to stdout
src/monitoring/metrics-export.sh serve 9090  # HTTP server
src/monitoring/metrics-export.sh watch       # Watch mode
```

## Troubleshooting

### Monitor Won't Start

```bash
# Check if already running
work monitor status

# Check for stale PID file
rm -f ~/.claude-work-data/monitor.pid

# Try starting again
work monitor start
```

### Metrics Not Updating

```bash
# Check daemon is running
work daemon status

# Manually generate metrics
work monitor metrics generate

# Check metrics file
cat ~/.claude-work-data/metrics.prom
```

### Health Check Failing

```bash
# Run verbose health check
work monitor health

# Check individual components
work daemon status
work api status

# Check state file
cat ~/.claude-work-data/context-state.json

# Check logs
tail -50 ~/.claude-work-data/daemon.log
tail -50 ~/.claude-work-data/health.log
```

## Alerting Examples

### Using Health Log

Monitor the health log for alerts:

```bash
# Watch for ERROR events
tail -f ~/.claude-work-data/health.log | grep ERROR

# Count errors in last hour
grep "ERROR" ~/.claude-work-data/health.log | grep "$(date -d '1 hour ago' '+%Y-%m-%d')" | wc -l
```

### Using Prometheus Alerts

Example `alerts.yml`:

```yaml
groups:
  - name: work_context_alerts
    interval: 30s
    rules:
      - alert: WorkDaemonDown
        expr: work_daemon_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Work Context Daemon is down"
          description: "The work context daemon has been down for more than 1 minute"
      
      - alert: WorkStateStale
        expr: work_state_age_seconds > 120
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Work context state is stale"
          description: "State hasn't been updated in {{ $value }} seconds"
      
      - alert: WorkHighMemoryUsage
        expr: work_daemon_memory_bytes > 157286400  # 150MB
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Work daemon high memory usage"
          description: "Memory usage is {{ $value | humanize }}B"
```

## Best Practices

1. **Run monitoring service alongside daemon**
   - Start both for full observability
   - Monitor service is lightweight (< 50MB RAM, 2% CPU)

2. **Set up Prometheus integration**
   - Scrape metrics every 15 seconds
   - Configure alerts for critical metrics

3. **Review health logs regularly**
   - Check for patterns in errors
   - Monitor state freshness

4. **Monitor resource usage**
   - Daemon should use < 100MB RAM
   - Monitor service should use < 50MB RAM
   - Combined CPU usage should be < 5%

5. **Test monitoring after updates**
   - Run health check after system changes
   - Verify metrics are updating
   - Check logs for errors

## Files and Locations

```
Project Structure:
├── src/monitoring/
│   ├── health-check.sh        # Health check implementation
│   ├── metrics-export.sh      # Prometheus metrics export
│   └── monitor-control.sh     # Monitoring service control
├── systemd/
│   └── work-monitor.service   # systemd service definition
└── monitoring.md              # This documentation

Data Files:
~/.claude-work-data/
├── health.log                 # Health event log
├── monitor.log                # Monitor service log
├── monitor.pid                # Monitor PID file
└── metrics.prom               # Prometheus metrics file
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Work Monitor Service                 │
│                                                       │
│  ┌─────────────────┐      ┌─────────────────┐      │
│  │  Health Check   │      │ Metrics Export  │      │
│  │   (every 10s)   │      │   (on demand)   │      │
│  └────────┬────────┘      └────────┬────────┘      │
│           │                         │                │
│           ├─── Daemon Status        │                │
│           ├─── API Status           │                │
│           ├─── State Freshness      ├─── Prometheus │
│           ├─── Memory Usage         │    Metrics    │
│           ├─── Disk Space           │                │
│           └─── Session Log          │                │
│                                      │                │
└──────────────────────────────────────┼──────────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │   Prometheus    │
                              │     Server      │
                              └─────────────────┘
```

## See Also

- [README.md](README.md) - Main documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [CLI.md](CLI.md) - CLI command reference
