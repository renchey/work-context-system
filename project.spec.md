# Project Specification: Work Context System

## Governance Reference

This project follows organizational standards defined in:
- **Repo**: `/home/renchey/projects/org-governance`
- **Git Strategy**: See `org-governance/workflows/git-branching-strategy.md`
- **Commit Format**: See `org-governance/standards/conventional-commits.md`
- **Code Standards**: See `org-governance/standards/`
- **PR Guidelines**: See `org-governance/workflows/pr-review-guidelines.md`

## Project Summary

**Work Context System**: Zero-friction context tracking that detects what users are actually working on across all tools using process-manager awareness.

## Problem Statement

Users with chaotic workflows need automatic context detection across:
- Terminal (pwd, git repo)
- IDE (VS Code, editor focus)
- Browser (active tab, document titles)
- Email (message subjects, sender context)
- Background processes (resource consumption, type)

Current approaches are either:
1. **App-specific**: Brittle, not portable, maintenance hell
2. **Terminal-only**: Misses 70% of actual context

## Solution

**Process-Manager-Based Detection**: Monitor system-level activity to infer context.

Track:
- Active window (xdotool/wmctrl)
- Process tree (ps, /proc/)
- File descriptors (lsof, /proc/[pid]/fd)
- Resource consumption (CPU, memory, I/O)
- Working directories

Infer context from actual behavior, not app assumptions.

## Why This Approach?

✅ **Universal** - Works with any tool
✅ **Portable** - No app-specific integrations
✅ **Resilient** - Self-healing when tools change
✅ **Accurate** - Detects actual activity

## Architecture Decision

See `ARCHITECTURE.md` for:
- Alternative approaches considered
- Rationale for process-manager approach
- Implementation phases

## Product Vision

**Internal Tool**: Better work awareness for personal productivity
**External Product**: Standalone dev-tool (context tracking, burndown, analytics)

## Scope

### Phase 1: Core Detection (Current)
- Active window detection
- Process tree analysis
- File descriptor inspection
- Basic context inference

### Phase 2: Project Mapping
- URL → Project mapping
- File path → Project mapping
- Process → Work type mapping
- Confidence scoring

### Phase 3: Daemon Integration
- Replace old passive system
- Real-time context logging
- AFK tracking
- Background process monitoring

### Phase 4: Output & Analytics
- Real-time status command
- Timeline visualization
- Work pattern analysis

## Technical Stack

- **Language**: Bash (shell scripts)
- **Detection**: xdotool, wmctrl, lsof, /proc/ inspection
- **Output**: JSON (jq)
- **Storage**: sessions.jsonl (JSON Lines)
- **Process**: Daemon (30s poll cycle)

## Key Files

```
work-context-system/
├── project.spec.md              # This file
├── ARCHITECTURE.md              # Decision log, phases, alternatives
├── README.md                    # User-facing docs
├── memory-bank/                 # Project memory (see below)
├── src/
│   ├── detectors/               # Detection modules
│   │   ├── active-window.sh
│   │   ├── process-tree.sh
│   │   ├── file-descriptors.sh
│   │   └── inference.sh
│   ├── mappers/                 # Context mapping
│   │   ├── url-to-project.sh
│   │   ├── file-path-to-project.sh
│   │   └── process-to-worktype.sh
│   └── daemon/                  # Core daemon
│       └── context-daemon.sh
└── tests/                       # Test suite
```

## Memory Bank

**Location**: `memory-bank/`

Tracks:
- `projectbrief.md` - Mission, objectives, key components
- `productContext.md` - Product vision, user stories, requirements
- `activeContext.md` - Current focus, recent accomplishments, blockers
- `progress.md` - Roadmap status, change log
- `agent-logbook.md` - Handoff notes, decisions, context for next agent

Updated continuously as work progresses.

## Success Criteria

✅ **Phase 1 Complete**
- [ ] All detectors operational and tested
- [ ] Detection accuracy >90% for foreground process
- [ ] <5% CPU overhead
- [ ] JSON output validated

✅ **Phase 2 Complete**
- [ ] Mapping rules cover top 30 projects
- [ ] URL extraction works for major platforms
- [ ] Confidence scoring functional

✅ **Phase 3 Complete**
- [ ] Daemon integration with real passive detection
- [ ] sessions.jsonl logging working
- [ ] Context switching detected automatically

✅ **Phase 4 Complete**
- [ ] `work-status-now` command shows real-time context
- [ ] `work-timeline` shows day's context switches
- [ ] Pattern analysis functional

## Handoff Notes

**Current Agent**: Claude Code (Initial Architecture)
**Next Agent**: GitHub Copilot (EOM - Implementation)
**Quota Available**: 60% today

**State Transfer**:
- Architecture decisions documented in ARCHITECTURE.md
- Memory bank initialized with current progress
- Phase 1 skeleton in place (detectors created but incomplete)
- Ready for implementation sprint

See `memory-bank/agent-logbook.md` for full context.

---

**Last Updated**: 2025-11-30
**Status**: Architecture Complete → Ready for Implementation
**Owner**: Work Context System Team
