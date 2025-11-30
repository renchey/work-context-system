# Project Brief: Work Context System

## Core Mission

Enable **zero-friction, automatic context tracking** for developers with chaotic workflows by using process-manager awareness instead of app-specific integrations.

## Key Objectives

1. **Detect Actual Context**: What is the user *really* working on right now (not assumptions)
2. **Universal**: Work with any tool (browser, IDE, terminal, email)
3. **Zero Friction**: Completely passive, no manual activation or logging
4. **Portable**: No hardcoded app integrations, system-level monitoring
5. **Accurate**: High confidence in context detection across context switches

## Core Components

### Detection Layer
- **Active Window** - What has focus (xdotool/wmctrl)
- **Process Tree** - What's consuming resources (ps, /proc/)
- **File Descriptors** - What files/networks are active (lsof, /proc/[pid]/fd)
- **Resource Monitoring** - CPU, memory, I/O patterns

### Inference Layer
- **URL → Project Mapping** - github.com/org/project → project context
- **File Path → Project Mapping** - ~/projects/x → project context
- **Process → Work Type Mapping** - npm, docker, code, browser, etc → work type
- **Confidence Scoring** - Multiple signals → high confidence decision

### Daemon Layer
- **Continuous Monitoring** - Every 30 seconds (configurable)
- **Change Detection** - Only log when context actually changes
- **AFK Tracking** - Detect inactive periods automatically
- **Background Work** - Monitor resource usage for cognitive load

### Output Layer
- **Real-Time Status** - `work-status-now` shows current context
- **Timeline Analysis** - `work-timeline` shows switches throughout day
- **Pattern Recognition** - `work-analyze` identifies work patterns

## Target Users

**Primary**: Developers with:
- Multiple active projects
- Spontaneous context switching
- Long background processes
- Reactive urgent work
- Unexpected interruptions (PC breaks, calls, etc)

**Secondary**: Anyone who wants to understand where their time actually goes

## Why Process-Manager Approach?

### ❌ App-Specific Integrations
- VS Code API → VS Code only
- Browser extension → specific browser
- Email client integration → one email client
- **Problem**: Brittle, not portable, maintenance nightmare

### ✅ Process-Manager Awareness
- Works with ANY editor
- Works with ANY browser
- Works with ANY email client
- **Benefit**: Universal, self-healing, portable

## Product Vision

### Phase 0 (Current): Architecture & Planning
- Decision: Process-manager approach chosen
- Design documented in ARCHITECTURE.md
- Team: Claude Code (architecture), GitHub Copilot (implementation)

### Phase 1: MVP (Core Detection)
- All detectors working (window, processes, FDs)
- Basic project mapping
- Daemon running
- ~1-2 weeks

### Phase 2: Intelligence Layer
- URL/file path → project mapping rules
- Confidence scoring
- Better heuristics
- ~1-2 weeks

### Phase 3: Daemon Integration
- Replace old passive system
- Real-time logging to sessions.jsonl
- AFK detection
- ~1 week

### Phase 4: Output & Analytics
- Real-time status commands
- Timeline visualization
- Pattern analysis
- ~1-2 weeks

### Phase 5: External Product
- Package as CLI dev-tool
- Integrate with other tools (Slack, calendar, etc)
- Support multiple platforms
- Future

## Success Metrics

- **Accuracy**: Detect foreground context >95% of the time
- **Performance**: <5% CPU overhead
- **Coverage**: Handle top 30 projects in org
- **Adoption**: Used daily by team
- **Extensibility**: Easy to add new work types, projects

## Technical Constraints

- **Bash-based**: Keep it lightweight, portable
- **Process inspection only**: No file content reading (privacy)
- **Window manager agnostic**: X11, Wayland, macOS (eventually)
- **30-second poll**: Lightweight daemon
- **JSON output**: Easy to parse, integrate

## Open Questions

1. What confidence threshold for context changes? (>80%, >90%?)
2. How to handle ambiguous contexts? (multiple signals conflict)
3. Privacy: How granular should FD inspection be?
4. Performance: Is 30s poll cycle sufficient?
5. Data retention: How long to keep sessions.jsonl?

## Non-Goals (For This Phase)

- ❌ IDE-specific APIs (too narrow)
- ❌ Browser extensions (too fragile)
- ❌ GUI/UI (MVP is CLI)
- ❌ Real-time updates to external systems
- ❌ Machine learning models (rules-based for now)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Process inspection too heavy | Performance degradation | Optimize queries, sample processes |
| Window manager incompatibility | Detection fails on some systems | Graceful fallbacks, multi-method detection |
| Ambiguous context signals | False positives in context detection | Confidence scoring, require multiple signals |
| Privacy concerns with FD inspection | User resistance | Document what's inspected, make optional |
| Shell integration limitations | Can't detect all context | Accept limitation, document scope |

## Sessions

- Session reports now live under `memory-bank/sessions/`. Each session file captures objectives, progress, metrics, and handover notes for smoother agent-to-agent transitions.
- Latest entry: `memory-bank/sessions/2025-11-30.md` (Phase 1 completion + next-step guidance).

---

**Created**: 2025-11-30
**Owner**: Work Context System
**Status**: Foundation Phase Complete → Ready for Implementation
