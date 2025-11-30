# Scripts: Task Management & Automation

Helper scripts for managing work on this project.

## Available Scripts

### `task-status.sh`
Show current task status, what needs to be done, and quick links to resources.

```bash
./scripts/task-status.sh
```

**Output**:
- Current active phase
- Tasks to complete
- Memory bank summary
- Quick links to documentation
- Next steps

**Use When**: Starting work session, need orientation

### `generate-task.sh`
Generate task briefing from project context (memory bank + architecture).

```bash
./scripts/generate-task.sh [phase]

# Examples
./scripts/generate-task.sh phase-1  # Creates TASK-PHASE-1.md
./scripts/generate-task.sh phase-2  # Creates TASK-PHASE-2.md
```

**Use When**: Creating new task briefings for handoff to agents

## Workflow

### Starting a Session
```bash
# See what needs to be done
./scripts/task-status.sh

# Read full task details
cat TASK-PHASE-1.md

# Get implementation context
cat memory-bank/agent-logbook.md
```

### During Implementation
```bash
# Test your code
./src/detectors/active-window.sh | jq .

# Update progress as you complete tasks
vim memory-bank/progress.md
```

### Completing a Phase
```bash
# Generate task briefing for next phase
./scripts/generate-task.sh phase-2

# Commit your work
git add -A
git commit -m "Complete Phase 1: Core detectors implemented

- Active window detection working
- Process tree analysis implemented
- File descriptor inspection functional
- Inference engine operational
- Test suite validates all components

Phase 2 ready for implementation."
```

## Memory Bank Updates

Keep memory bank current as you work:

**`progress.md`**:
- Add completed tasks to changelog
- Update Phase status
- Mark metrics as you hit them

**`activeContext.md`**:
- Note accomplishments
- Document blockers if any
- Update "Next Steps"

**`agent-logbook.md`**:
- Add implementation notes
- Document decisions made
- Note edge cases discovered

## Extending Scripts

To add new management scripts:

1. Create in `scripts/` directory
2. Make executable: `chmod +x scripts/your-script.sh`
3. Document in this README
4. Update `task-status.sh` if needed to link to it

---

**Owner**: Work Context System Team
**Updated**: 2025-11-30
