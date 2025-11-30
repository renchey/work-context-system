#!/bin/bash
# generate-task.sh: Create actionable task briefing from project context

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHASE="${1:-phase-1}"
OUTPUT="${PROJECT_DIR}/TASK-${PHASE^^}.md"

echo "Generating task briefing for: $PHASE"
echo "Output: $OUTPUT"

# This is a template. In production, would:
# 1. Read memory-bank files
# 2. Extract relevant sections
# 3. Generate task breakdown
# 4. Output to TASK-X.md

cat > "$OUTPUT" << 'TASK_TEMPLATE'
# TASK: Phase X - [Task Name]

## Generated From
- `memory-bank/projectbrief.md`
- `memory-bank/agent-logbook.md`
- `ARCHITECTURE.md`

## Mission
[Mission extracted from memory bank]

## Success Criteria
[Criteria from projectbrief.md]

## Tasks
[Breakdown from agent-logbook.md]

## Resources
- Full context: `memory-bank/`
- Architecture: `ARCHITECTURE.md`
- Spec: `project.spec.md`

---
Generated: $(date)
TASK_TEMPLATE

echo "✓ Task briefing created: $OUTPUT"
echo ""
echo "Next steps:"
echo "1. Review: cat $OUTPUT"
echo "2. Get context: cat $PROJECT_DIR/memory-bank/agent-logbook.md"
echo "3. Start implementation"
