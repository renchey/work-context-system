# Work Context System - Troubleshooting Guide

## Common Issues

### Daemon Not Starting

**Symptom**: `work-daemon start` fails or daemon stops immediately

**Possible Causes**:

1. **Missing dependencies**
   ```bash
   # Check for required tools
   which jq xdotool wmctrl lsof
   
   # Install missing tools (Debian/Ubuntu)
   sudo apt-get install jq xdotool wmctrl lsof
   ```

2. **Permission issues**
   ```bash
   # Check data directory permissions
   ls -la ~/.claude-work-data
   
   # Fix permissions
   chmod 755 ~/.claude-work-data
   chmod 644 ~/.claude-work-data/*.json
   chmod 644 ~/.claude-work-data/*.jsonl
   ```

3. **Port already in use**
   ```bash
   # Check if port 3042 is in use
   lsof -i :3042
   
   # Use different port
   PORT=3043 work-daemon start
   ```

**Solution**:
```bash
# Stop any existing daemon
pkill -f "work-context-system.*daemon"

# Clear state files
rm ~/.claude-work-data/context-state.json

# Start fresh
./src/daemon/daemon.sh start
```

---

### No Context Detected

**Symptom**: API returns "No active context" or `unknown` project

**Possible Causes**:

1. **No active window detected**
   ```bash
   # Test window detection
   bash src/detectors/active-window.sh
   
   # Should output JSON with window info
   ```

2. **Working in unmapped project**
   - Context system may not recognize your project yet
   - Projects auto-discovered from git repos and URLs

3. **Daemon not running**
   ```bash
   # Check daemon status
   pgrep -f "work-context-system.*daemon"
   
   # Start if not running
   ./src/daemon/daemon.sh start
   ```

**Solution**:

Add manual project mapping:
```bash
# Add your project path to mapper
echo '{"path": "/home/renchey/projects/my-project"}' | bash src/mappers/path-mapper.sh
```

---

### Slow Detection

**Symptom**: Context detection takes >2 seconds

**Diagnosis**:
```bash
# Time each detector
time bash src/detectors/active-window.sh
time bash src/detectors/process-tree.sh
time bash src/detectors/file-descriptors.sh

# Check inference engine
time bash src/inference-combined.sh
```

**Solutions**:

1. **Optimize slow detectors**:
   - Limit process tree depth
   - Filter file descriptors by type
   - Cache static mappings

2. **Reduce polling frequency**:
   ```bash
   # Edit daemon.sh poll interval
   # Change: sleep 5
   # To:     sleep 10
   ```

3. **Skip expensive detectors**:
   ```bash
   # Disable FD inspection if not needed
   # Comment out in inference-combined.sh
   ```

---

### High Memory Usage

**Symptom**: Daemon uses >100MB RAM

**Diagnosis**:
```bash
# Check daemon memory
ps aux | grep "daemon.sh"

# Check for memory leaks in Node.js API
ps aux | grep "node.*api.js"
```

**Solutions**:

1. **Rotate session logs**:
   ```bash
   # Move old sessions
   mv ~/.claude-work-data/sessions.jsonl \
      ~/.claude-work-data/sessions.$(date +%Y%m).jsonl
   
   # Start fresh log
   touch ~/.claude-work-data/sessions.jsonl
   ```

2. **Limit log retention**:
   ```bash
   # Keep only last 30 days
   find ~/.claude-work-data -name "sessions.*.jsonl" -mtime +30 -delete
   ```

3. **Restart daemon periodically**:
   ```bash
   # Add to crontab for daily restart
   0 0 * * * pkill -f "work-context-system.*daemon" && \
             /path/to/work-context-system/src/daemon/daemon.sh start
   ```

---

### API Not Responding

**Symptom**: Cannot reach `http://localhost:3042/api/status`

**Diagnosis**:
```bash
# Check if API server is running
pgrep -f "node.*api.js"

# Check port
lsof -i :3042

# Test API manually
curl http://localhost:3042/api/status
```

**Solutions**:

1. **Start API server**:
   ```bash
   cd /path/to/work-context-system
   node src/server/api.js
   ```

2. **Check for port conflicts**:
   ```bash
   # Use different port
   PORT=3043 node src/server/api.js
   ```

3. **Check firewall**:
   ```bash
   # Allow port through firewall (if needed)
   sudo ufw allow 3042/tcp
   ```

---

### Incorrect Project Detection

**Symptom**: Wrong project name detected

**Diagnosis**:
```bash
# Check inference output
bash src/inference-combined.sh | jq .

# Check signal traces
bash src/inference-combined.sh | jq '.signals'
```

**Solutions**:

1. **Add project-specific mapping**:
   Edit `src/mappers/url-mapper.sh` or `path-mapper.sh`:
   ```bash
   # Add your domain/path pattern
   case "${url_domain}" in
       "mycompany.com") echo "my-internal-project" ;;
   esac
   ```

2. **Increase confidence threshold**:
   Edit `src/inference-combined.sh`:
   ```bash
   # Require higher confidence for detection
   if [ "${confidence}" -ge 80 ]; then
   ```

3. **Check git remote URL**:
   ```bash
   # Ensure git remote matches expected pattern
   cd /path/to/project
   git remote -v
   ```

---

### Missing Session Data

**Symptom**: Timeline or analytics show no data

**Diagnosis**:
```bash
# Check session log exists
ls -lh ~/.claude-work-data/sessions.jsonl

# View recent entries
tail -20 ~/.claude-work-data/sessions.jsonl

# Count total events
wc -l ~/.claude-work-data/sessions.jsonl
```

**Solutions**:

1. **Verify daemon is logging**:
   ```bash
   # Watch for new entries
   tail -f ~/.claude-work-data/sessions.jsonl
   
   # Switch context and verify new entry appears
   ```

2. **Check file permissions**:
   ```bash
   # Ensure writable
   chmod 644 ~/.claude-work-data/sessions.jsonl
   ```

3. **Restore from backup**:
   ```bash
   # If you have backups
   cp ~/.claude-work-data/backup/sessions.jsonl ~/.claude-work-data/
   ```

---

### Dashboard Not Loading

**Symptom**: Web UI shows blank page or errors

**Diagnosis**:
```bash
# Check browser console for errors
# Open Developer Tools (F12)

# Verify API is reachable
curl http://localhost:3042/api/status

# Check web files exist
ls web/dashboard.html
```

**Solutions**:

1. **Ensure API server is running**:
   ```bash
   node src/server/api.js
   ```

2. **Clear browser cache**:
   - Hard refresh: Ctrl+Shift+R (Linux/Windows) or Cmd+Shift+R (Mac)

3. **Check CORS settings**:
   - API should have CORS enabled for localhost

4. **Verify file paths**:
   ```bash
   # API serves static files from web/
   ls -la web/
   ```

---

## Performance Troubleshooting

### Detection Latency

If detection feels slow:

1. **Profile individual components**:
   ```bash
   time bash src/detectors/active-window.sh
   time bash src/mappers/url-mapper.sh
   time bash src/inference-combined.sh
   ```

2. **Optimize bottlenecks**:
   - Add caching for static mappings
   - Reduce process tree depth
   - Limit file descriptor scanning

3. **Adjust polling frequency**:
   - Increase daemon sleep interval
   - Reduce real-time requirements

### Storage Growth

If `sessions.jsonl` grows too large:

1. **Implement log rotation**:
   ```bash
   # Monthly rotation script
   #!/bin/bash
   month=$(date +%Y%m)
   mv ~/.claude-work-data/sessions.jsonl \
      ~/.claude-work-data/sessions.${month}.jsonl
   touch ~/.claude-work-data/sessions.jsonl
   ```

2. **Archive old sessions**:
   ```bash
   # Compress old logs
   gzip ~/.claude-work-data/sessions.*.jsonl
   ```

3. **Clean up old data**:
   ```bash
   # Keep only last 3 months
   find ~/.claude-work-data -name "sessions.*.jsonl.gz" -mtime +90 -delete
   ```

---

## System-Specific Issues

### Wayland Compatibility

**Issue**: `xdotool` doesn't work on Wayland

**Solutions**:

1. **Use Wayland-compatible tools**:
   - Replace `xdotool` with `wlrctl` (sway/wlroots)
   - Use `gdbus` for GNOME

2. **Switch to X11 session**:
   - Select "Ubuntu on Xorg" at login screen

3. **Use alternative detection**:
   - Focus on process tree and file paths
   - Disable active window detection

### macOS Compatibility

**Issue**: Linux-specific tools not available

**Solutions**:

1. **Install Homebrew alternatives**:
   ```bash
   brew install jq
   ```

2. **Use macOS APIs**:
   - Replace `xdotool` with AppleScript
   - Use `lsof` for file descriptors (works on macOS)

3. **Adapt detectors**:
   - Fork detectors for macOS-specific APIs

### Docker/VM Environments

**Issue**: Limited system access in containers

**Solutions**:

1. **Mount `/proc` filesystem**:
   ```bash
   docker run -v /proc:/proc:ro ...
   ```

2. **Use host networking**:
   ```bash
   docker run --network=host ...
   ```

3. **Run daemon on host**:
   - Deploy daemon outside container
   - Container only runs API/UI

---

## Debugging Tips

### Enable Debug Logging

Add debug output to scripts:
```bash
# At top of script
set -x  # Enable trace mode

# Or selectively
echo "[DEBUG] Variable value: ${var}" >&2
```

### Monitor Daemon Activity

```bash
# Watch daemon logs (if logging to file)
tail -f /tmp/work-context-daemon.log

# Monitor process
watch -n 1 'ps aux | grep daemon.sh'

# Watch session file
watch -n 1 'tail -5 ~/.claude-work-data/sessions.jsonl'
```

### Test Individual Components

```bash
# Test detector
bash src/detectors/active-window.sh | jq .

# Test mapper with sample input
echo '{"url": "github.com/test/repo"}' | bash src/mappers/url-mapper.sh | jq .

# Test full inference
bash src/inference-combined.sh | jq .
```

### Validate JSON Output

```bash
# Validate detector output
bash src/detectors/active-window.sh | jq . > /dev/null && echo "Valid JSON"

# Pretty-print for inspection
bash src/inference-combined.sh | jq . | less
```

---

## Getting More Help

1. **Check logs**: `~/.claude-work-data/*.log`
2. **Review docs**: `ARCHITECTURE.md`, `PROJECT-ARCHITECTURE.md`, `API-REFERENCE.md`
3. **GitHub Issues**: [Open an issue](https://github.com/renchey/work-context-system/issues)
4. **Discussions**: [Ask in discussions](https://github.com/renchey/work-context-system/discussions)
5. **Memory Bank**: Check `memory-bank/` for project context

## Reporting Bugs

When reporting issues, include:
- OS and version
- Shell version (`bash --version`)
- Tool versions (`jq --version`, `xdotool --version`)
- Error messages
- Output of detection test: `bash src/inference-combined.sh`
- Daemon status: `pgrep -f daemon.sh`

## Emergency Reset

If all else fails, reset completely:

```bash
# Stop all processes
pkill -f "work-context-system"

# Backup existing data
cp -r ~/.claude-work-data ~/.claude-work-data.backup

# Clear all state
rm -rf ~/.claude-work-data

# Recreate directory
mkdir -p ~/.claude-work-data

# Start fresh
./src/daemon/daemon.sh start
node src/server/api.js
```
