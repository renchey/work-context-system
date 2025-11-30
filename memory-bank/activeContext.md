# Active Context

## Current Phase: Phase 1 Complete → Phase 2 In Progress

Core detectors, inference, and validation suite are live. Phase 2 mapping heuristics now being implemented. See `memory-bank/sessions/2025-11-30-phase1-review.md` for Phase 2 readiness assessment.

## Recent Accomplishments

- **Detector Stack**: Active window, process tree, and file descriptor detectors emit spec-compliant JSON
- **Inference Engine**: Aggregates detector output into project/work-type + confidence
- **Test Harness**: `tests/test-detection.sh` validates JSON + performance (<2s / detector)
- **Architecture Decision**: Process-manager approach over app-specific integrations
- **Project Structure**: Aligned with org-governance standards
- **Memory Bank & Spec**: Established for future agents

## Active Work

- [x] Identify problem with existing passive system (daemon doesn't track user's shell directory)
- [x] Design process-manager-based alternative
- [x] Document architecture decision
- [x] Create project structure aligned to org-standards
- [x] Set up memory bank
- [x] Implement Phase 1 (Core Detection) - **Completed 2025-11-30**
- [ ] Plan Phase 2 mapping + heuristics expansion
- [ ] Define Phase 3 daemon integration milestones

## Current Blockers

**None** - Architecture is complete, ready for implementation phase.

## Next Steps

1. **Phase 2 Kickoff** - URL/file/project mapping heuristics + confidence tuning
2. **Phase 3 Prep** - Plan daemon orchestration + polling cadence validation
3. **Phase 4 Lookahead** - Define CLI output contracts (`work-status-now`, etc.)

## Decision Points Made

### 1. Process-Manager vs App-Specific (RESOLVED)
**Decision**: Process-manager approach
- Universal, portable, self-healing
- No app-specific integrations
- Works with tools user chooses, not what we hardcode

### 2. Bash vs Other Languages (RESOLVED)
**Decision**: Bash shell scripts
- Lightweight, portable
- Native process inspection tools available
- Easy for others to extend/modify

### 3. Detection Frequency (RESOLVED)
**Decision**: 30-second poll cycle
- Lightweight enough for daemon
- Captures context switches quickly enough
- Can be tuned later if needed

## Open Questions

1. **Confidence Threshold**: What % confidence required to log context change? (80%, 90%?)
2. **Ambiguous Contexts**: How to handle when multiple signals suggest different contexts?
3. **Data Retention**: How long to keep sessions.jsonl before rotating?
4. **Performance Targets**: Actual CPU/memory overhead we're seeing
5. **Edge Cases**: Window manager variants, container environments, SSH sessions

## Team Notes

**Renchey** (Product Owner):
- Identified limitation in passive system (daemon process isolation)
- Pushed for system-level monitoring instead of app integrations
- Emphasized browser/email as critical context sources
- Will review implementation and set direction

**Claude Code** (Architecture):
- Designed process-manager-based approach
- Documented decisions in ARCHITECTURE.md
- Set up project structure and memory bank
- Ready to hand off to implementation team

**GitHub Copilot** (EOM - Implementation):
- Delivered all Phase 1 detectors + inference + tests (runtime guard at 2s)
- Documented behavior updates in README/START-HERE/TASK-PHASE-1
- Ready to support Phase 2 planning + handoff artifacts

---

**Last Updated**: 2025-11-30
**Next Review**: Phase 2 kickoff
**Owner**: Work Context System Team

## Update — 2025-11-30 (Append-Only Note)

- Memory bank entries now follow an append-only policy; status changes are captured by adding new sections (see `memory-bank/progress.md` snapshot dated 2025-11-30).
- Current state: Phase 1 deliverables complete; outstanding items focus on Phase 2 mapping heuristics, Phase 3 daemon integration, and Phase 4 output commands.
- Completed vs. Still To Do lists live at the end of `memory-bank/progress.md` for continuity.
