#!/bin/bash
# task-status.sh: Show current task status and what needs to be done

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  WORK CONTEXT SYSTEM - TASK STATUS                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Show active phase
if [ -f "$PROJECT_DIR/TASK-PHASE-1.md" ]; then
    echo "📋 ACTIVE TASK: Phase 1 - Core Detection"
    echo ""
    echo "Current Tasks:"
    grep "^### Task" "$PROJECT_DIR/TASK-PHASE-1.md" | sed 's/### Task /  - Task /'
    echo ""
fi

# Show memory bank summary
echo "📚 MEMORY BANK:"
echo ""
if [ -f "$PROJECT_DIR/memory-bank/activeContext.md" ]; then
    echo "  Current Focus:"
    grep "^## " "$PROJECT_DIR/memory-bank/activeContext.md" | head -1 | sed 's/## /    /'
    echo ""
fi

# Show progress
if [ -f "$PROJECT_DIR/memory-bank/progress.md" ]; then
    echo "  Progress:"
    grep "^### Phase" "$PROJECT_DIR/memory-bank/progress.md" | head -1 | sed 's/### /    /'
    echo ""
fi

# Show quick links
echo "🔗 QUICK LINKS:"
echo ""
echo "  Task Details:"
echo "    cat TASK-PHASE-1.md"
echo ""
echo "  Full Context:"
echo "    cat memory-bank/agent-logbook.md"
echo ""
echo "  Project Spec:"
echo "    cat project.spec.md"
echo ""
echo "  Architecture:"
echo "    cat ARCHITECTURE.md"
echo ""

# Show what to do next
echo "▶️  NEXT STEPS:"
echo ""
echo "  1. Read full task context:"
echo "     cat TASK-PHASE-1.md"
echo ""
echo "  2. Get implementation details:"
echo "     cat memory-bank/agent-logbook.md"
echo ""
echo "  3. Start Task 1 (Active Window Detector):"
echo "     vim src/detectors/active-window.sh"
echo ""
echo "  4. Test as you go:"
echo "     ./src/detectors/active-window.sh | jq ."
echo ""
echo "  5. Update progress:"
echo "     vim memory-bank/progress.md"
echo ""
