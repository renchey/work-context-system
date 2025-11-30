# Active Context

## Current Phase: Architecture & Design

We're transitioning from discovery (broken passive system) to implementation (process-manager-based solution).

## Recent Accomplishments

- **Architecture Decision**: Chose process-manager approach over app-specific integrations
- **Decision Log**: Documented rationale in ARCHITECTURE.md
- **Project Structure**: Aligned with org-governance standards
- **Memory Bank**: Created standard memory bank structure
- **Specification**: Created project.spec.md with full handoff notes

## Active Work

- [x] Identify problem with existing passive system (daemon doesn't track user's shell directory)
- [x] Design process-manager-based alternative
- [x] Document architecture decision
- [x] Create project structure aligned to org-standards
- [x] Set up memory bank
- [ ] Implement Phase 1 (Core Detection) - **Handed off to GitHub Copilot**

## Current Blockers

**None** - Architecture is complete, ready for implementation phase.

## Next Steps

1. **GitHub Copilot EOM Sprint** - Implement Phase 1 (detectors)
2. **Phase 1 Completion** - All core detectors functional and tested
3. **Phase 2** - Project mapping and inference layer
4. **Phase 3** - Daemon integration
5. **Phase 4** - Output and analytics commands

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
- Will implement Phase 1 (core detectors)
- Starting with active window detection
- 60% quota available today
- Deadline: Implementation complete this sprint

---

**Last Updated**: 2025-11-30
**Next Review**: After Phase 1 implementation
**Owner**: Work Context System Team
