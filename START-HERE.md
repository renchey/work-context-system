# START HERE: Phase 1 Implementation Kickoff

Welcome! You're implementing **Phase 1: Core Detection** for the Work Context System.

## Quick Start (5 mins)

```bash
# 1. Navigate to project
cd ~/projects/work-context-system

# 2. See what needs to be done
./scripts/task-status.sh

# 3. Read the full task
cat TASK-PHASE-1.md

# 4. Get implementation context
cat memory-bank/agent-logbook.md

# 5. Start with Task 1
vim src/detectors/active-window.sh
```

## What You're Building

**Active Window Detection** → **Process Tree Analysis** → **File Descriptor Inspection** → **Inference Engine** → **Tests**

All 5 components together form Phase 1. Each builds on the others.

## Success Looks Like

✅ All 4 detectors working
✅ Can run: `./src/detectors/active-window.sh | jq .`
✅ Can test inference with known projects
✅ <5% CPU overhead, <2 seconds per run
✅ All tests passing

## File Structure You'll Be Working In

```
work-context-system/
├── src/detectors/              # ← You implement these 4
│   ├── active-window.sh        # Task 1: Window detection
│   ├── process-tree.sh         # Task 2: Process analysis
│   ├── file-descriptors.sh     # Task 3: FD inspection (create)
│   └── inference.sh            # Task 4: Context inference (create)
├── tests/
│   └── test-detection.sh       # Task 5: Test suite (create)
├── memory-bank/                # ← Update these as you go
│   ├── progress.md             # Update: add completed tasks
│   ├── activeContext.md        # Update: blockers/accomplishments
│   └── agent-logbook.md        # Update: implementation notes
├── TASK-PHASE-1.md            # ← Your task blueprint (detailed!)
├── ARCHITECTURE.md             # Context: why we chose this approach
└── project.spec.md             # Context: full project spec
```

## Development Workflow

### 1. Pick a Task (Start with Task 1)
```bash
cat TASK-PHASE-1.md | grep "^### Task 1" -A 30
```

### 2. Implement
```bash
vim src/detectors/active-window.sh
```

### 3. Test Immediately
```bash
./src/detectors/active-window.sh | jq .
# Should output valid JSON with your window info
```

### 4. Move to Next Task
Loop through all 5 tasks, testing each one.

### 5. Update Progress
```bash
vim memory-bank/progress.md
# Add to change log: "Completed Task 1: Active Window Detection"

vim memory-bank/activeContext.md
# Note accomplishment, any blockers
```

## Key Resources

| What | Where | When |
|------|-------|------|
| Your task breakdown | `TASK-PHASE-1.md` | Before you start |
| Full implementation context | `memory-bank/agent-logbook.md` | If you get stuck |
| Architecture decisions | `ARCHITECTURE.md` | To understand why |
| Project vision | `memory-bank/projectbrief.md` | For big picture |
| How to run tests | `TASK-PHASE-1.md` → "Task 5: Test Suite" | After implementing |

## Testing as You Go

**Recommended Testing Pattern**:

```bash
# Task 1: After implementing active-window.sh
firefox https://github.com/Mallow-Dev/stock-v3 &
sleep 1
./src/detectors/active-window.sh | jq .
# Should show Firefox, github URL, stock-v3 project path

# Task 2: After implementing process-tree.sh
npm run dev &
./src/detectors/process-tree.sh | jq .
# Should show nodejs in categories

# Task 3: After implementing file-descriptors.sh
./src/detectors/file-descriptors.sh | jq .
# Should show network connections, project paths

# Task 4: After implementing inference.sh
./src/detectors/inference.sh | jq .
# Should infer: project=stock-v3, work_type=code-review, high confidence

# Task 5: Create test suite
bash tests/test-detection.sh
# All tests should pass
```

## If You Get Stuck

**Blocker?** Check these resources in order:

1. **Implementation Details** - `TASK-PHASE-1.md` has detailed specs
2. **Implementation Notes** - `memory-bank/agent-logbook.md` has tips
3. **Architecture** - `ARCHITECTURE.md` explains the why
4. **Previous Implementation** - `src/detectors/active-window.sh` has skeleton code

## Committing Your Work

After each task or logical group:

```bash
git add -A
git commit -m "Implement Task 1: Active window detection

- Detects active window using xdotool/wmctrl
- Extracts PID, process name, window title
- Reads process info from /proc/
- Returns valid JSON output
- Handles fallback when tools unavailable

Task 1 ✓ Complete"
```

## Success Criteria Checklist

**Phase 1 status (2025-11-30)**:

- [x] Task 1: Active Window Detector (working + tested)
- [x] Task 2: Process Tree Analyzer (working + tested)
- [x] Task 3: File Descriptors Inspector (working + tested)
- [x] Task 4: Inference Engine (working + tested)
- [x] Task 5: Test Suite (all tests passing)
- [x] All JSON outputs validated
- [x] Performance verified (<5% CPU, <2s per detector via `tests/test-detection.sh`)
- [x] Memory bank updated with progress (see `memory-bank/`)
- [x] Documentation updated in code & docs

## When Phase 1 Is Done

You'll have:
✅ 4 functional detectors
✅ Inference engine
✅ Full test suite
✅ <5% CPU overhead
✅ Documentation

**Next**: Hand off to Phase 2 (Project Mapping) with updated memory bank

## Quick Command Reference

```bash
# Check task status anytime
./scripts/task-status.sh

# Show task details
cat TASK-PHASE-1.md

# Test your detector
./src/detectors/active-window.sh | jq .

# Update progress
vim memory-bank/progress.md

# Commit work
git add -A && git commit -m "description"

# See what you've built
git log --oneline
```

## Final Notes

- **You've got this** - Architecture is solid, tasks are clear, resources are complete
- **Test often** - Run detectors immediately after writing
- **Document as you go** - Update memory bank with accomplishments
- **Reach out** - If blocked, context is in memory bank
- **Have fun** - This is actually cool tech you're building

---

**Ready?** Start with:
```bash
./scripts/task-status.sh
cat TASK-PHASE-1.md
vim src/detectors/active-window.sh
```

Good luck! 🚀
