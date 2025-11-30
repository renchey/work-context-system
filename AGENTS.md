# AGENTS

## Roles & Responsibilities

| Role | Owner | Focus |
|------|-------|-------|
| Product Owner | Renchey | Vision, priorities, acceptance criteria, unblock decisions |
| Architect | Claude Code | System design, architecture docs, governance patterns |
| Implementation Agent | GitHub Copilot | Execute phase tasks, maintain detectors/tests, document progress |
| Future Agents | TBD | Continue Phase 2+, extend mapping heuristics, daemon, analytics |

## Engagement Model
1. Open a session by running `./scripts/task-status.sh`, then read `START-HERE.md` + relevant `TASK-PHASE-*.md`.
2. Update memory bank (`memory-bank/*.md`) in append-only style with accomplishments, blockers, and next steps.
3. After substantial work, add/append to `memory-bank/sessions/<date>.md` summarizing context, metrics, and handover notes.
4. Keep `.github/copilot-instructions.md` accurate when workflows or tooling change.

## Handoff Expectations
- **Before coding**: confirm current phase in `memory-bank/progress.md` + `activeContext.md`.
- **During work**: log notable decisions in `memory-bank/agent-logbook.md`.
- **After work**: ensure tests pass (`./tests/test-detection.sh`), document outcomes, and outline open questions for the next agent.

## Point of Contact
- Strategy/product: Renchey
- Architecture decisions: Claude Code
- Implementation support: Current GitHub Copilot assignee (see session log)
