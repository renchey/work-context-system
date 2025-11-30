# Active Context

## Current Phase: Phase 2 Complete → Preparing Phase 3

Core detectors, mappers, inference confidence scoring, and validation suite are live. Focus shifts to daemon integration + output surfaces. See `memory-bank/sessions/2025-11-30.md` for the latest session wrap-up.

## Recent Accomplishments

- **Mapping Layer**: URL/file/process mappers (`src/mappers/*.sh`) feed inference with scored project/work-type candidates
- **Inference Engine**: Aggregates detector + mapper signals with improved confidence scoring + signal trace
- **Test Harness**: `tests/test-detection.sh` validates detectors + mappers, JSON shape, and performance (<2s / detector)
- **Detector Stack**: Active window, process tree, and file descriptor detectors emit spec-compliant JSON
- **Architecture Decision**: Process-manager approach over app-specific integrations
- **Project Structure / Memory Bank**: Aligned with org governance and append-only policy

## Active Work

- [x] Identify problem with existing passive system (daemon doesn't track user's shell directory)
- [x] Design process-manager-based alternative
- [x] Document architecture decision
- [x] Create project structure aligned to org-standards
- [x] Set up memory bank
- [x] Implement Phase 1 (Core Detection) - **Completed 2025-11-30**
- [x] Implement Phase 2 (Mapping + Scoring) - **Completed 2025-11-30**
- [ ] Implement Phase 3 (Daemon integration + sessions logging)
- [ ] Define Phase 4 output/analytics milestones + dashboard/notification scope

## Current Blockers

**None** - Architecture is complete, ready for implementation phase.

## Next Steps

1. **Phase 3 Execution** - Build daemon loop, sessions logging, AFK/background load monitoring
2. **Phase 4 Prep** - Define CLI output contracts (`work-status-now`, `work-timeline`, `work-analyze`) and dashboard/API interfaces
3. **Notifications & Mobile** - Draft design for desktop alerts + phone companion/remote-control signals

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
- Delivered Phase 1 detectors + Phase 2 mapping/inference upgrades (runtime guard at 2s)
- Documented behavior updates in README/START-HERE/TASK-PHASE-1 and memory bank
- Ready to support Phase 3 daemon build + dashboard/notification planning

---

## Update — 2025-11-30 (Phase 2 Wrap)

- Mapping heuristics + inference scoring completed; repo now emits consistent project/work-type w/ explicit signal logs.
- Tests expanded to cover new mappers; watch `tests/test-detection.sh` output for performance regressions.
- Next focus: daemon integration + dashboard/notification design spike.

**Last Updated**: 2025-11-30
**Next Review**: After Phase 3 implementation plan lands
**Owner**: Work Context System Team

## Update — 2025-11-30 (Append-Only Note)

- Memory bank entries now follow an append-only policy; status changes are captured by adding new sections (see `memory-bank/progress.md` snapshot dated 2025-11-30).
- Current state: Phase 1 deliverables complete; outstanding items focus on Phase 2 mapping heuristics, Phase 3 daemon integration, and Phase 4 output commands.
- Completed vs. Still To Do lists live at the end of `memory-bank/progress.md` for continuity.
