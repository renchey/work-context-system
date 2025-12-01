## Copilot Instructions

### Quick Context
- Process-manager-based work context tracker; architecture + rationale live in `ARCHITECTURE.md` and `project.spec.md`.
- Core Bash detectors (`active-window.sh`, `process-tree.sh`, `file-descriptors.sh`) emit JSON that `src/detectors/inference.sh` merges with mapper hints.
- Mapping heuristics in `src/mappers/` (URL/file-path/process) return `{project, confidence, signals}` blocks consumed by inference scoring.
- Memory bank under `memory-bank/` is append-only history for progress, context, and session handoffs.

### Daily Workflow
1. Run `./scripts/task-status.sh`, then read `START-HERE.md` and the current `TASK-PHASE-*.md` to understand goals.
2. Modify detectors or mappers while preserving JSON schemas; prefer building JSON via printf/heredocs and validate with `jq`.
3. Execute `./tests/test-detection.sh` after each change; it runs detectors, inference, and mapper sanity checks while enforcing the <2s/process-tree budget.
4. Append updates to `memory-bank/activeContext.md`, `progress.md`, `agent-logbook.md`, and start/extend a `memory-bank/sessions/<YYYY-MM-DD>.md` entry when handing off.

### Coding Standards
- Stay within existing POSIX toolset (ps, jq, lsof, xdotool, wmctrl) and gate optional utilities with detection helpers.
- Avoid per-process subshells; reuse cached listings and incremental parsing to stay under the runtime budget, especially inside `process-tree.sh`.
- Mapping scripts may consult `$PROJECTS_ROOT` (defaults to `~/projects`); cache directory scans per invocation to prevent slow walks.
- Emit timestamps via `date -u +%Y-%m-%dT%H:%M:%SZ`; keep comments short and focused on non-obvious parsing or perf tricks.

### Testing & Diagnostics
- `./tests/test-detection.sh` is the authoritative suite; it also jq-validates every detector output—fix formatting before re-running if it fails.
- For isolated performance work run `/usr/bin/time -f '%E real' ./src/detectors/process-tree.sh` and keep real time <2.0s.
- Spot-check JSON contracts with commands like `./src/detectors/active-window.sh | jq '.pid, .process_name'` or `./src/detectors/inference.sh | jq '.'`.

### Documentation & Tooling
- Keep `README.md` project status and workflows up to date; `scripts/README.md` documents helper scripts that must remain executable.
- Use Prettier for formatting, markdownlint for Markdown checks, and CSpell (en-GB) for spell-checking outside of code blocks.
- `AGENTS.md` tracks responsibilities; update it only when roles change, but always follow its engagement model during sessions.

### Handoff Essentials
- Never rewrite history in memory-bank docs—only append new sections with timestamps and context.
- Capture blockers/decisions in `memory-bank/agent-logbook.md` and reflect phase transitions in `memory-bank/progress.md`.
- Leave explicit TODOs or open questions in the latest session log so the next agent can resume without re-parsing the full archive.

> If any workflow or tooling expectation changes (new detector, mapper, or test), update this document alongside the related code.
