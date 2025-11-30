# Copilot Instructions

## Quick Context
- Product: process-manager-based work context tracker (see ARCHITECTURE.md for rationale vs. app-specific integrations).
- Code lives in Bash detectors under `src/detectors/`; inference consumes JSON emitted by active-window, process-tree, and file-descriptors scripts.
- Memory bank (memory-bank/*.md) is append-only; add new sections/snapshots instead of editing history.

## Daily Workflow
1. Run `./scripts/task-status.sh` for current phase/tasks, then read `START-HERE.md` and the relevant `TASK-PHASE-*.md`.
2. Implement or edit detectors under `src/detectors/` and mapping heuristics under `src/mappers/`, keeping JSON output stable (validate with `jq`).
3. Execute `./tests/test-detection.sh` after detector/mapper changes; it checks schema + enforces <2s runtime (process-tree is tight at ~2s) and now includes mapper sanity tests.
4. Update memory bank docs (progress, activeContext, agent-logbook, sessions) via appended sections summarizing accomplishments/blockers.
5. When handing off, add a new `memory-bank/sessions/<YYYY-MM-DD>.md` report with context, progress, metrics, and next steps.

## Coding Conventions
- Stick to POSIX/Bash utilities already used (ps, jq, lsof, xdotool, wmctrl); guard optional dependencies with helper checks.
- Buffer JSON fragments via printf/Here-strings instead of repeated `jq` processes; avoid per-process subshells (performance budget is strict).
- Mapping scripts may read `$PROJECTS_ROOT` (defaults to `~/projects`)—avoid expensive scans and cache directory listings per invocation when possible.
- Keep comments terse; only annotate non-obvious parsing/perf tricks.
- All timestamps are UTC ISO-8601 via `date -u +%Y-%m-%dT%H:%M:%SZ`.

## Testing & Diagnostics
- Primary test entrypoint: `./tests/test-detection.sh` (runs detectors + mappers sequentially, jq-validates output, and times critical scripts).
- For focused perf work on process-tree, use `/usr/bin/time -f '%E real' ./src/detectors/process-tree.sh` and keep under 2.0s real.
- Use `jq` for schema spot-checks: `./src/detectors/active-window.sh | jq '.pid, .process_name'` etc.

## Documentation & Signposts
- README.md carries product story + quick start; keep “Project Status” current with links to major docs.
- `AGENTS.md` records roles/responsibilities; `CONTRIBUTORS.md` thanks humans/agents by milestone.
- Scripts reference: `scripts/README.md`; generator + status scripts live in `scripts/` and must stay executable.

## Handoff Essentials
- Always append to memory-bank docs and logbooks; never delete historical lines.
- Record blockers/decisions in `memory-bank/agent-logbook.md` and update `memory-bank/progress.md` snapshots when phases shift.
- Leave TODOs or open questions in the newest session report so the next agent can resume without re-reading the entire history.

> If anything above becomes inaccurate (new detectors, new tests, changed budgets), update this file alongside the relevant code/doc.
