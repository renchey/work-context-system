# TASK: Phase 1 - Core Detection Implementation

## Mission

Implement all core process-manager detectors that automatically identify what the user is working on by analyzing active processes, window focus, and resource usage.

## Success Criteria (Must Complete All)

- [ ] All 4 detectors functional and tested
- [ ] CPU overhead <5% for 30-second poll cycle
- [ ] Execution time <2 seconds per detection cycle
- [ ] All outputs are valid JSON
- [ ] Error handling for edge cases
- [ ] Test suite with unit tests for each detector
- [ ] Documentation updated with detection results

## Task Breakdown

### Task 1: Active Window Detector
**File**: `src/detectors/active-window.sh`
**Status**: Skeleton started, needs completion

**What It Does**:
Detects which window/process has user focus right now.

**Inputs**: None (reads system state)

**Outputs** (JSON):
```json
{
  "pid": 12345,
  "process_name": "firefox",
  "window_title": "Pull Request #123 - GitHub",
  "process_cwd": "/home/renchey/projects/stock-v3",
  "process_cmdline": "firefox --profile ...",
  "timestamp": "2025-11-30T06:35:22"
}
```

**Implementation Details**:
1. Use `xdotool getactivewindow` to get window ID (primary)
2. Fallback to `wmctrl -l` if xdotool unavailable
3. Extract PID using `xdotool getwindowpid`
4. Get window title with `xdotool getwindowname`
5. Read process info from `/proc/[pid]/`
6. Extract working directory from `/proc/[pid]/cwd`
7. Get command line from `/proc/[pid]/cmdline`
8. Output as JSON

**Testing**:
```bash
# Should show Firefox window
firefox https://github.com/some/pr &
sleep 1
./src/detectors/active-window.sh | jq .

# Should show VS Code
code /path/to/project &
sleep 1
./src/detectors/active-window.sh | jq .

# Should have valid JSON
./src/detectors/active-window.sh | jq empty && echo "Valid JSON" || echo "Invalid JSON"
```

**Done When**:
- Works with xdotool installed
- Falls back gracefully when xdotool unavailable
- Returns valid JSON
- Correctly identifies active window on test system

---

### Task 2: Process Tree Analyzer
**File**: `src/detectors/process-tree.sh`
**Status**: Skeleton created, needs implementation

**What It Does**:
Analyzes all running processes to identify work type and resource consumption.

**Inputs**: None (reads system state)

**Outputs** (JSON):
```json
{
  "intensive_process_count": 3,
  "categories": {
    "nodejs": 2,
    "docker": 1,
    "browser": 1
  },
  "processes": 4,
  "timestamp": "2025-11-30T06:35:22"
}
```

**Implementation Details**:
1. Get all processes with `ps aux`
2. For each process, extract:
   - PID, name, memory usage (from `/proc/[pid]/status`)
   - CPU usage (from `ps` output)
   - Command line (from `/proc/[pid]/cmdline`)
3. Filter to "intensive" processes (>100MB OR >5% CPU)
4. Categorize by process type:
   - `browser`: chrome, firefox, safari, edge
   - `editor`: code, vim, nvim, emacs
   - `nodejs`: node, npm, npx
   - `python`: python, python3, pip
   - `container`: docker, podman
   - `git-ssh`: git, ssh, scp
   - `shell`: bash, zsh, sh, fish
   - `email`: thunderbird, evolution, mutt
   - `chat`: slack, discord, telegram
   - `http`: curl, wget
   - `dev-server`: webpack, vite, rollup, dev server processes
   - `testing`: jest, mocha, ava, pytest
   - `other`: everything else
5. Count processes per category
6. Output JSON with counts and total

**Testing**:
```bash
# Start some background processes
npm run dev &
docker run -d some/image &
firefox &
sleep 2

# Should detect them
./src/detectors/process-tree.sh | jq .

# Should show:
# - nodejs category (npm)
# - docker category
# - browser category
```

**Done When**:
- Correctly categorizes top 10 process types
- Accurately counts intensive processes
- Returns valid JSON
- Handles cases where processes die between checks

---

### Task 3: File Descriptors Inspector
**File**: `src/detectors/file-descriptors.sh`
**Status**: Not started, create new

**What It Does**:
Inspects open files/network connections of active processes to extract context clues (project paths, URLs, git repos).

**Inputs**: None (reads system state via lsof)

**Outputs** (JSON):
```json
{
  "file_descriptors": {
    "git_repos": [
      "/home/renchey/projects/stock-v3/.git"
    ],
    "open_urls": [
      "github.com/Mallow-Dev/stock-v3"
    ],
    "project_paths": [
      "/home/renchey/projects/stock-v3"
    ],
    "network_connections": [
      "github.com:443",
      "localhost:3000"
    ]
  },
  "timestamp": "2025-11-30T06:35:22"
}
```

**Implementation Details**:
1. Use `lsof` to get open files for active process
2. Filter for interesting types:
   - Regular files with `~/projects/` in path → project context
   - Files with `.git/` in path → git repo context
   - Network sockets → extract domain/IP
3. Parse URLs from network connections
4. Extract project names from paths
5. Output JSON with categorized results
6. Handle cases where process has no interesting FDs

**Testing**:
```bash
# With Firefox showing GitHub
firefox https://github.com/Mallow-Dev/stock-v3/pull/123 &
sleep 2

# Should detect
./src/detectors/file-descriptors.sh | jq .

# Should show:
# - github.com in URLs
# - Network connection info
```

**Done When**:
- Extracts project paths correctly
- Identifies network connections
- Returns valid JSON
- Gracefully handles lsof unavailable or process has no FDs

---

### Task 4: Inference Engine
**File**: `src/detectors/inference.sh`
**Status**: Not started, create new

**What It Does**:
Combines signals from all 3 detectors to make a confident determination of current context (project + work type + confidence score).

**Inputs**:
- Output from active-window.sh
- Output from process-tree.sh
- Output from file-descriptors.sh

**Outputs** (JSON):
```json
{
  "project": "stock-v3",
  "work_type": "code-review",
  "confidence": 0.95,
  "signals": [
    "cwd=/home/renchey/projects/stock-v3",
    "window_title contains github.com",
    "active_process=firefox",
    "network_connection=github.com:443"
  ],
  "timestamp": "2025-11-30T06:35:22"
}
```

**Implementation Details**:
1. Take JSON from all 3 detectors as input
2. Extract signals:
   - From active-window: cwd, process_name, window_title
   - From process-tree: current work types (coding vs browsing vs email)
   - From file-descriptors: git repos, URLs, project paths
3. Apply heuristics:
   - If process_cwd contains `~/projects/X`, project = X
   - If window_title contains github.com, likely code-review
   - If process is Firefox + github.com connection, code-review
   - If process is VS Code + cwd in ~/projects/X, development on X
   - If process is Terminal + ssh connection, ops work
4. Score confidence (0.0-1.0):
   - Multiple signals agreeing = high confidence (0.8-1.0)
   - Single signal = lower confidence (0.5-0.7)
   - No clear signals = unknown (0.0-0.3)
5. Output JSON with project, work_type, confidence, and signals

**Work Type Categories**:
- `development` - Writing code (VS Code + project)
- `code-review` - Reviewing code (GitHub + Firefox/Chrome)
- `documentation` - Writing docs (Editor + Google Docs/internal wiki)
- `ops-deployment` - Server work (Terminal + SSH connection)
- `communication` - Email/chat (Thunderbird/Slack open)
- `research` - Learning/research (Browser + time spent reading)
- `testing` - Running tests (npm test, pytest running)
- `debugging` - Debugging code (VS Code + debugger active)
- `unknown` - Can't determine

**Testing**:
```bash
# Test Case 1: Code Review
firefox https://github.com/Mallow-Dev/stock-v3/pull/123 &
sleep 1
project=$(./src/detectors/inference.sh | jq -r .project)
worktype=$(./src/detectors/inference.sh | jq -r .work_type)
# Should be: project=stock-v3, work_type=code-review

# Test Case 2: Development
code ~/projects/mallow-ai &
npm run dev &
sleep 1
./src/detectors/inference.sh | jq .
# Should be: project=mallow-ai, work_type=development

# Test Case 3: Ops Work
ssh deploy@87.106.72.197 &
sleep 1
./src/detectors/inference.sh | jq .
# Should be: project=stock-v3 (from context), work_type=ops-deployment
```

**Done When**:
- Correctly infers context from combined signals
- Confidence scoring is reasonable (0.8+ for clear cases)
- Returns valid JSON
- All test cases pass

---

### Task 5: Test Suite
**File**: `tests/test-detection.sh`
**Status**: Not started, create new

**What It Does**:
Comprehensive test suite validating all detectors.

**Test Coverage**:
```bash
#!/bin/bash
# Test suite for all detectors

# Test 1: Active window detection
test_active_window() {
  # Verify JSON output
  # Check required fields
  # Verify PID is valid
  # Check working directory exists
}

# Test 2: Process tree analysis
test_process_tree() {
  # Verify JSON output
  # Check categories are valid
  # Verify counts match actual processes
}

# Test 3: File descriptors
test_file_descriptors() {
  # Verify JSON output
  # Check paths are valid
  # Verify network connections parsed correctly
}

# Test 4: Inference engine
test_inference() {
  # Verify JSON output
  # Check confidence is 0.0-1.0
  # Verify project name matches expected
  # Check work_type is valid
}

# Test 5: Performance
test_performance() {
  # Measure CPU during detection
  # Measure execution time
  # Verify <5% CPU, <2 seconds
}

# Test 6: Error handling
test_error_handling() {
  # What if xdotool not installed?
  # What if no active window?
  # What if process dies mid-detection?
  # What if lsof not available?
}
```

**Running Tests**:
```bash
cd /home/renchey/projects/work-context-system
bash tests/test-detection.sh

# Should output:
# ✓ Active window detection
# ✓ Process tree analysis
# ✓ File descriptors
# ✓ Inference engine
# ✓ Performance (<5% CPU, <2s)
# ✓ Error handling
# All tests passed!
```

**Done When**:
- All test cases pass
- Tests can run on target system (Ubuntu Linux)
- Performance validated (<5% CPU, <2 seconds)
- Edge cases tested and documented

---

## Implementation Order

1. **First**: Task 1 (Active Window) - Foundational
2. **Second**: Task 2 (Process Tree) - Independent
3. **Third**: Task 3 (File Descriptors) - Independent
4. **Fourth**: Task 4 (Inference) - Depends on 1-3
5. **Fifth**: Task 5 (Tests) - Can happen in parallel, validate all

## Technical Reference

### JSON Validation
```bash
# Always test JSON output
./src/detectors/active-window.sh | jq empty && echo "Valid" || echo "Invalid"
```

### Performance Testing
```bash
# Measure execution time
time ./src/detectors/active-window.sh

# Measure CPU during execution
(while true; do ps aux | grep active-window; done) &
./src/detectors/active-window.sh
```

### Error Handling Template
```bash
# Check if command exists
if ! command -v xdotool &> /dev/null; then
    echo "Error: xdotool not found" >&2
    exit 1
fi

# Check if file readable
if [ ! -r "/proc/$pid/cwd" ]; then
    echo "{\"error\": \"Cannot read process cwd\"}" | jq .
    exit 1
fi
```

## Documentation Requirements

Update as you complete:
1. `memory-bank/progress.md` - Add completed tasks to change log
2. `memory-bank/activeContext.md` - Update blockers/accomplishments
3. `README.md` - Document detector behavior/output

## Success Indicators

By end of Phase 1:
- [ ] Can run detectors individually and see JSON output
- [ ] Can chain detectors into inference pipeline
- [ ] Test output with known projects (stock-v3, mallow-ai)
- [ ] Verify accuracy >95% on test cases
- [ ] Performance <5% CPU, <2 seconds
- [ ] All code documented and tested

## Known Challenges

1. **Window manager compatibility**: X11 works, Wayland might need adjustment
2. **Process categorization**: Some processes may not fit categories
3. **Confidence scoring**: Hard to know right thresholds without testing
4. **Privacy**: FD inspection might reveal sensitive info (document this)
5. **Edge cases**: Containers, SSH sessions, tmux might behave differently

## Resources

- `ARCHITECTURE.md` - Design decisions, why process-manager approach
- `memory-bank/agent-logbook.md` - Full context and escalation points
- `memory-bank/productContext.md` - Why this matters
- `project.spec.md` - Full project specification

## Quota Usage

- **Available**: 60% today
- **Estimate for Phase 1**: 40-50% (4 detectors + tests)
- **Keep buffer**: Leave 10% for debugging/tweaks

---

**Status**: Ready to implement
**Created**: 2025-11-30
**Phase**: 1 of 4
**Owner**: GitHub Copilot (EOM)
**Duration**: Target completion today (one sprint)

**Start here**: Implement Task 1 (Active Window Detector) first.
