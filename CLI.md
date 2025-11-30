# Work Context System - CLI Guide

Complete command reference for the `work` CLI.

## Quick Start

```bash
# Initialize system
work init

# Start tracking
work daemon start

# Check your current work context
work status

# View today's context switches
work timeline today

# Stop tracking
work daemon stop
```

## Full Command Reference

### Daemon Management

**Start background tracking daemon**
```bash
work daemon start
# Output: ✓ Daemon started (PID: 12345)
```

**Stop daemon gracefully**
```bash
work daemon stop
# Output: ✓ Daemon stopped (was PID: 12345)
```

**Restart daemon**
```bash
work daemon restart
# Stops and restarts the daemon
```

**Check daemon status**
```bash
work daemon status
# Output:
# ✓ Daemon running (PID: 12345)
#
# Recent log entries:
# [2025-11-30 22:45:00] Context changed to: stock-v3
# [2025-11-30 22:46:00] Background process count: 3
```

**Watch daemon logs in real-time**
```bash
work daemon logs
# Tails daemon.log with updates as they happen
# Press Ctrl+C to exit
```

---

### Current Work Status

**Show real-time work context**
```bash
work status
# or
work now

# Output:
# ╔════════════════════════════════════════════════════════════════╗
# ║  WORK STATUS (Real-Time)                                       ║
# ╚════════════════════════════════════════════════════════════════╝
#
#   📂 Project: stock-v3
#   🎯 Work Type: development
#   🔒 Confidence: 87%
#   📊 Status: 🟢 Active
#   🐳 Background Processes: 3
#
#   ⚠️  Cognitive load: ▓▓▓░░░░░░
```

**Fields**:
- **Project**: Detected from window title, file path, or URL
- **Work Type**: code-review, development, testing, ops-deployment, communication, documentation, research, debugging, unknown
- **Confidence**: How confident the system is (0-100%)
- **Status**: Active (green) or AFK/Away (blue)
- **Background Processes**: Number of active processes (CPU load indicator)

---

### Timeline & History

**View context switches today**
```bash
work timeline today
# Shows all context changes with timestamps
```

**View context switches this week**
```bash
work timeline week
# Shows context changes for past 7 days
```

**Example output**:
```
╔════════════════════════════════════════════════════════════════╗
║  WORK TIMELINE (today)                                         ║
╚════════════════════════════════════════════════════════════════╝

  ⏰ 09:15:32 → 📂 Context changed to: stock-v3
  ⏰ 09:22:15 → 📂 Context changed to: mallow-ai
  ⏰ 10:35:00 → 💤 AFK detected (22 min)
  ⏰ 10:57:15 → 🟢 Back active
  ⏰ 11:05:30 → 📂 Context changed to: stock-v3
  ⏰ 14:30:00 → 🐳 Background work: 4 processes (increase)
```

---

### Analytics & Analysis

**Show work statistics**
```bash
work analyze
# Shows summary of projects, time allocation, patterns

# Output:
# 📊 OVERVIEW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Total events logged: 247
#   Context switches: 23
#   AFK periods detected: 5
#   Background process changes: 18
#
# 📂 PROJECTS WORKED ON
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   stock-v3               18 switches
#   mallow-ai               4 switches
#   health-safety           1 switches
#
# ⏱️  AFK ANALYSIS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Total AFK time: ~67 minutes
#   Average AFK period: ~13 minutes
#   AFK events: 5
```

---

### Manual Annotations

**Add note to current work**
```bash
work note "Debugging performance issues in auth service"
# Output: ✓ Note added

# Later: view notes in timeline or raw logs
```

**Use cases**:
- Document what you're actually working on (when auto-detection is wrong)
- Add context for future review
- Clarify ambiguous work types
- Mark milestones or context switches

---

### System Configuration

**Show current configuration**
```bash
work config
# Output:
# Work Context System Configuration
#
# Data directory: /home/renchey/.claude-work-data/
# Session log: /home/renchey/.claude-work-data/sessions.jsonl
# State file: /home/renchey/.claude-work-data/context-state.json
# Daemon log: /home/renchey/.claude-work-data/daemon.log
#
# Poll interval: 30 seconds
# AFK threshold: 15 minutes
```

**Initialize system**
```bash
work init
# Creates necessary directories and files
```

**Reset all data** ⚠️
```bash
work reset
# Deletes all session history
# Asks for confirmation first
```

---

### Help

**Show help**
```bash
work help
# or
work --help
# or
work -h
```

---

## Workflows

### Daily Workflow

```bash
# Morning: Start tracking
work daemon start

# Throughout day: Check status
work status      # Show current work

# Add notes when auto-detection is wrong
work note "Debugging auth flow"

# If interrupted: Work shows AFK period automatically

# Before meetings/breaks: Check cognitive load
work status      # Shows background process count

# Before shutdown: Stop tracking
work daemon stop
```

### Capacity Planning

```bash
# Check current load
work status
# If process count > 5, you're at high load

# Review time allocation
work analyze
# See which projects took most context switches

# Plan next sprint
work timeline today
# Review context switches to identify patterns
```

### Performance Review

```bash
# End of week review
work analyze
# Shows projects worked on, time allocation

work timeline week
# Detailed timeline of all context switches

# Use data for:
# - Time tracking / billing
# - Understanding work patterns
# - Identifying bottlenecks (many AFK periods?)
# - Load distribution across projects
```

---

## Data Files

**Sessions Log** (`~/.claude-work-data/sessions.jsonl`)
- One JSON event per line
- Includes: context changes, AFK periods, background work
- Kept for analysis and history
- ~50KB per day (rotate manually or via cron)

**Current State** (`~/.claude-work-data/context-state.json`)
- Snapshot of current work state
- Updated every 30 seconds by daemon
- Used by `work status` command

**Daemon Log** (`~/.claude-work-data/daemon.log`)
- Daemon startup/shutdown events
- Errors and issues
- Useful for debugging

---

## Troubleshooting

**Daemon not starting**
```bash
work daemon status
# Check if already running

work daemon logs
# Look for error messages
```

**No project detected**
```bash
work status
# If shows "unknown", try:
# 1. Ensure you're in ~/projects/[name]
# 2. Check git remote is configured
# 3. Use `work note` to manually specify

# Or add URL to url-to-project mapping
```

**High CPU usage**
```bash
work analyze
# Check if too many background processes

# Reduce background tasks or:
# - Increase poll interval (edit daemon)
# - Close unnecessary applications
```

**AFK not detecting correctly**
```bash
# AFK threshold is 15 minutes of shell inactivity
# Not accurate for IDE-only work or SSO logins
# Use manual notes: work note "In meeting"
```

---

## Integration Examples

### Slack Status Auto-Update

```bash
#!/bin/bash
# Auto-update Slack status with current work
while true; do
    project=$(cat ~/.claude-work-data/context-state.json | jq -r '.saved_project')
    worktype=$(cat ~/.claude-work-data/context-state.json | jq -r '.data.work_type')

    # Use Slack API to update status
    # slack_api_call "update_status" "$project: $worktype"

    sleep 300  # Update every 5 mins
done
```

### Calendar Auto-Blocking

```bash
#!/bin/bash
# Block calendar when context switching is high
while true; do
    switches=$(grep -c '"context_change"' ~/.claude-work-data/sessions.jsonl)

    if [ $switches -gt 20 ]; then
        # Auto-block calendar for 1 hour
        # calendar_api_call "block" "1h" "High context switching"
    fi

    sleep 600  # Check every 10 mins
done
```

### Daily Email Report

```bash
#!/bin/bash
# Send end-of-day work summary

timestamp=$(date +%Y-%m-%d)
summary=$(work analyze)

# Email with:
# - Projects worked on
# - Time allocation
# - Context switches
# - AFK periods
```

---

## Advanced Usage

### Export Data

```bash
# Export all sessions as JSON
cat ~/.claude-work-data/sessions.jsonl | jq -s '.'

# Export specific project data
grep 'stock-v3' ~/.claude-work-data/sessions.jsonl

# Time-based export
grep '2025-11-30' ~/.claude-work-data/sessions.jsonl
```

### Raw Data Analysis

```bash
# Count context switches per project
jq -r '.data.project' ~/.claude-work-data/sessions.jsonl | \
    sort | uniq -c | sort -rn

# Find longest AFK period
grep 'afk_detected' ~/.claude-work-data/sessions.jsonl | \
    jq '.data.idle_minutes' | sort -rn | head -1

# Average session length
jq -r '.timestamp' ~/.claude-work-data/sessions.jsonl | \
    wc -l
```

---

## Performance

- **Daemon CPU**: <5% on average
- **Memory**: <50MB
- **Log growth**: ~50KB/day
- **Poll latency**: <2 seconds per cycle
- **Detection accuracy**: 85-95% (depends on browser/IDE awareness)

---

**For more info**: See README.md and ARCHITECTURE.md
