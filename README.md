# Work Context System

**Zero-friction work context tracking for chaotic developers.**

Automatically detects what you're working on across all tools—terminal, IDE, browser, email—without any manual logging or activation.

## Repository Signposts

- **Getting Started**: `START-HERE.md` → orientation + workflow
- **Current Tasks**: `TASK-PHASE-1.md` (Phase 1 reference) & run `./scripts/task-status.sh`
- **Architecture**: `ARCHITECTURE.md` for the process-manager decision + phase plan
- **Agents**: `AGENTS.md` (roles, responsibilities, handoff expectations)
- **Contributors**: `CONTRIBUTORS.md` (append-only acknowledgements)
- **Copilot Instructions**: `.github/copilot-instructions.md` (agent workflow + testing guardrails)
- **Memory Bank**: `memory-bank/` (progress, active context, sessions log)
- **Scripts**: `scripts/README.md` (task generator + status helper)

## Problem

You jump between projects spontaneously. You have long background processes running. You get interrupted by urgent work. You take unexpected AFK breaks. And sometimes you spend 2 hours on something without realizing it.

Traditional time tracking is friction-heavy. Passive tracking doesn't capture reality. The current system doesn't know what's in your browser tab, where your mental context actually is.

## Solution

Watch the process manager. Monitor:
- **Active window** - What's in focus right now?
- **Process hierarchy** - What's consuming resources?
- **File descriptors** - What files/networks are active?
- **Working directories** - Where are processes running?

Infer context from reality, not assumptions.

## Why Process-Manager Approach?

❌ **App-specific integrations** - Brittle, not portable, maintenance hell
✅ **Process-manager awareness** - Universal, self-healing, works with any tool

Whether you use Chrome or Firefox, Thunderbird or Gmail, VS Code or Vim—the system detects your actual activity.

## Core Idea

```bash
$ work-status-now
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ACTIVE RIGHT NOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📂 Project: stock-v3
  🎯 Work Type: code-review
  🪟 Active: Firefox (github.com PR review)
  ⏱️  Duration: 34 minutes

  🐳 Background: 2 docker containers
  📊 Cognitive Load: Getting busy (3 tasks)
```

## Project Status

**Phase**: Phase 2 mapping heuristics complete — prepping for daemon integration.

**Current Deliverables**
- Active window, process tree, and file descriptor detectors emit JSON per spec
- Phase 2 mappers (`src/mappers/*.sh`) resolve URL/file/process signals → project/work-type candidates
- Inference engine stitches detector + mapper output into project/work-type with confidence scoring + signal trace
- `tests/test-detection.sh` verifies detectors, mappers, JSON schemas, and enforces <2s detector runtime

**Docs to Read Next**
- `memory-bank/progress.md` → timeline + completed vs. pending work
- `memory-bank/sessions/2025-11-30.md` → latest session summary + handover notes
- `src/mappers/` → mapping heuristics for URLs, paths, processes feeding inference

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design decisions.

## Quick Start (WIP)

```bash
# Start daemon
work-daemon start

# Check current context (real-time)
work-status-now

# View timeline of what you worked on
work-timeline

# Analyze your work patterns
work-analyze
```

## Could Be...

- **Internal tool** for your workflow
- **External product** (CLI dev-tool)
- **Integration point** (Slack status, calendar blocking, etc)

## Development

See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation plan.

```
Phase 1: Core detection (active window, process tree, FDs)
Phase 2: Project mapping & inference
Phase 3: Daemon integration
Phase 4: Output & UI
```
