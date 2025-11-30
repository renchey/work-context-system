# Work Context System - Architecture Decision

## Project Overview

**Goal**: Zero-friction work context tracking that automatically detects what the user is actually working on across all tools and workflows.

**Status**: Architecture decision in progress (Decision Point: Process-Aware Detection)

## Context

User has:
- Multiple active projects (stock-v3, mallow-ai, health-safety, etc)
- Chaotic workflow: jumps between projects spontaneously
- Long background processes
- Reactive urgent work constantly
- AFK periods (PC fixes, calls, hardware issues)
- Uses: Terminal, VS Code, Browser (multiple tabs), Email client

## Previous Approach: Application-Specific Integration (Rejected)

Attempted to track:
- Shell working directory via daemon
- VS Code workspace detection
- Browser tab URL parsing
- Email client monitoring

**Problem**: Required hardcoding integrations for every app. Brittle, not portable, missed context when switching contexts.

## Decision Point: Process-Manager-Based Detection (Current)

**New Approach**: Monitor system-level activity rather than app-specific APIs.

### Core Concept
Instead of "is Firefox open?", ask: "What does the user have active RIGHT NOW?"

**Detection sources**:
1. **Active window** - Which process has focus? (xdotool/wmctrl)
2. **Process tree** - What's consuming resources?
3. **File descriptors** - What files/networks are active?
4. **Working directories** - Where are processes running?
5. **Process metadata** - Parent-child relationships, execution context

### Why This Works
- **Universal**: Works with ANY tool (IDE, browser, email, terminal)
- **Accurate**: Detects actual activity, not assumptions
- **Portable**: No app-specific integrations needed
- **Resilient**: If user switches to new tools, system still works

### Example Context Detection

```
Scenario 1: Code Review
├─ Active window: Firefox
│  └─ Process: firefox (parent: init)
│     ├─ FD: github.com connection (socket)
│     ├─ Working dir: /home/renchey (browser's cwd)
│     └─ Window title: "Mallow-Dev/stock-v3 Pull Request #123"
└─ Inferred context: stock-v3 / code-review

Scenario 2: Development
├─ Active window: VS Code
│  └─ Process: code (parent: systemd)
│     ├─ Open file: /home/renchey/projects/stock-v3/src/api.ts
│     ├─ Working dir: /home/renchey/projects/stock-v3
│     └─ Child processes: node (dev server on :3000)
└─ Inferred context: stock-v3 / development

Scenario 3: Operations Work
├─ Active window: Terminal
│  └─ Process: bash (parent: gnome-terminal)
│     ├─ Working dir: /home/renchey/server-management
│     ├─ Command line: ssh deploy@87.106.72.197
│     └─ Child processes: ssh, scp
└─ Inferred context: stock-v3 / deployment

Scenario 4: Communication
├─ Active window: Thunderbird
│  └─ Process: thunderbird (parent: init)
│     ├─ Window title: "RE: stock-v3 deployment - urgent"
│     └─ FD: IMAP connection to mail server
└─ Inferred context: stock-v3 / communication
```

## Implementation Plan

### Phase 1: Core Detection
- [ ] Active window detection (xdotool/wmctrl)
- [ ] Process tree analysis (`ps`, `/proc/`)
- [ ] File descriptor inspection (`lsof`, `/proc/[pid]/fd`)
- [ ] Context inference engine

### Phase 2: Project Mapping
- [ ] URL → Project mapping (github.com, docs, internal tools)
- [ ] File path → Project mapping
- [ ] Process name → Work type mapping
- [ ] Heuristic-based confidence scoring

### Phase 3: Daemon Integration
- [ ] Replace old passive daemon with process-aware daemon
- [ ] Log context changes to sessions.jsonl
- [ ] Track AFK periods (no window activity)
- [ ] Monitor background process load

### Phase 4: Output & UI
- [ ] `work-status-now` - Show current context (real-time)
- [ ] `work-timeline` - Show context switches throughout day
- [ ] `work-analyze` - Analyze work patterns (what takes time)

## Open Questions

1. **Window manager agnostic?** (X11 vs Wayland vs macOS)
2. **Privacy**: How granular should FD inspection be? (avoid reading file contents)
3. **Confidence scoring**: How do we handle ambiguous contexts?
4. **Performance**: Running every 30 seconds - is process analysis too heavy?

## Product Potential

This could be:
- **Internal tool**: For better work context awareness in your own workflow
- **External tool**: Could be packaged as CLI dev-tool for others (context tracking, burndown tracking)
- **Integration point**: Hook for other tools (Slack status, calendar blocking, email autoresponse)

## Files Structure

```
work-context-system/
├── ARCHITECTURE.md (this file)
├── DECISION-LOG.md (decision history)
├── src/
│   ├── detectors/
│   │   ├── active-window.sh
│   │   ├── process-tree.sh
│   │   ├── file-descriptors.sh
│   │   └── inference.sh
│   ├── mappers/
│   │   ├── url-to-project.sh
│   │   ├── file-path-to-project.sh
│   │   └── process-to-worktype.sh
│   └── daemon/
│       └── context-daemon.sh
├── tests/
│   └── test-detection.sh
└── README.md (user-facing docs)
```

## Decision Log

### 2025-11-30: Initial Architecture Decision

**Alternative 1**: Application-Specific Integrations
- Pros: Precise, app-native APIs
- Cons: Brittle, not portable, maintenance burden

**Alternative 2**: Process-Manager-Based (CHOSEN)
- Pros: Universal, portable, self-healing
- Cons: Less precise, needs heuristics

**Decision**: Go with process-manager approach. More valuable as a general tool.

---

Next: Implement Phase 1 (Core Detection)
