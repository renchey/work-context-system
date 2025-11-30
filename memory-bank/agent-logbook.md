# Agent Logbook: Handoff Notes

## For GitHub Copilot (EOM - Implementation)

### Phase 1 Completion Notes (2025-11-30)

- All four detectors (`active-window`, `process-tree`, `file-descriptors`, `inference`) emit stable JSON and handle missing-tool fallbacks.
- `tests/test-detection.sh` exercises each detector, validates JSON via `jq`, and enforces the <2s runtime budget (current `process-tree` ~2.0s).
- CPU overhead remains within the <5% target for the 30-second polling plan; memory footprint dominated by `lsof` when present.
- Documentation refreshed (README, START-HERE, TASK-PHASE-1) so future agents immediately see completion status + expectations for Phase 2.
- Remaining focus shifts to Phase 2 mapping heuristics and Phase 3 daemon integration (see "Questions for Next Phase" below).

### Phase 2 Completion Notes (2025-11-30)

- Added mapping utilities under `src/mappers/` (URL → project, file-path → project, process → work_type) plus shared heuristics (PROJECTS_ROOT aware).
- `inference.sh` now aggregates detector + mapper signals, maintains per-project confidence scores, and surfaces a richer signal log.
- `tests/test-detection.sh` invokes the new mappers to ensure deterministic JSON + regression protection alongside the existing runtime budget checks.
- README + memory-bank docs updated to reflect Phase 2 completion; Copilot instructions now call out mapper workflow + testing requirements.
- Next milestones focus on Phase 3 daemon loop (sessions logging, AFK/background load) and Phase 4 output/notification/dashboard surfaces.

### Handoff Summary

You're taking over the **Work Context System** project for Phase 1 implementation.

**Your Mission**: Implement all core detectors (active window, process tree, file descriptors, basic inference).

**Resources**:
- 60% quota available today
- Full memory bank in `memory-bank/`
- Architecture documented in `ARCHITECTURE.md`
- Project spec in `project.spec.md`
- README has user-facing docs

### What You're Inheriting

**Good News**:
1. Architecture is complete and validated
2. Project structure aligned to org-standards
3. Decision log is documented (why process-manager approach)
4. Memory bank ready for updates
5. Clear implementation phases

**Known Issues**:
1. Old passive system has broken daemon (process doesn't track user's pwd)
2. No browser/email context detection yet (Phase 2+)
3. Detection scripts started but incomplete
4. Need to handle window manager compatibility (X11, Wayland, macOS eventually)

### Your Phase 1 Tasks

**Priority 1** (Must Complete):
```
1. [ ] Implement active-window.sh detector
   - Works with xdotool and wmctrl
   - Detects PID, process name, window title
   - JSON output
   - Handles fallback when xdotool unavailable

2. [ ] Implement process-tree.sh detector
   - Get process info (name, memory, CPU, cmdline)
   - Categorize processes (browser, editor, nodejs, etc)
   - Count intensive processes
   - JSON output

3. [ ] Implement file-descriptors.sh detector
   - Use lsof to get open files/networks
   - Filter by interesting types (sockets, networks, git repos)
   - Extract context clues (github.com, project paths)
   - JSON output

4. [ ] Build inference.sh engine
   - Take outputs from detectors
   - Combine signals for context determination
   - Simple heuristics (pwd + active window + FDs)
   - Output: project + worktype + confidence
   - JSON output
```

**Priority 2** (Nice to Have):
```
5. [ ] Create test suite
   - Test each detector with known inputs
   - Verify JSON output format
   - Check error handling
   - Performance testing (<5% CPU)

6. [ ] Document detector behavior
   - What each detector does
   - Input/output format
   - Known limitations
   - Edge cases
```

### Key Technical Details

**Output Format**: All detectors must output valid JSON (for piping into inference engine)

**Example Active Window Output**:
```json
{
  "pid": 12345,
  "process_name": "firefox",
  "window_title": "Pull Request #123 - GitHub",
  "process_cwd": "/home/user/projects/stock-v3",
  "process_cmdline": "firefox --profile /home/user/.mozilla/firefox/...",
  "timestamp": "2025-11-30T06:35:22"
}
```

**Example Process Tree Output**:
```json
{
  "intensive_process_count": 3,
  "categories": {
    "nodejs": 2,
    "docker": 1,
    "browser": 1
  },
  "processes": 4,
  "timestamp": "2025-11-30T06:35:22"
}
```

**Example Inference Output**:
```json
{
  "project": "stock-v3",
  "work_type": "code-review",
  "confidence": 0.95,
  "signals": [
    "cwd=/home/renchey/projects/stock-v3",
    "window_title contains github.com",
    "process=firefox"
  ],
  "timestamp": "2025-11-30T06:35:22"
}
```

### Success Criteria for Phase 1

✅ **All Detectors Working**
- [ ] Active window detector: Works on both xdotool and wmctrl systems
- [ ] Process tree analyzer: Correctly categorizes top 10 process types
- [ ] File descriptor inspector: Extracts files, networks, URLs
- [ ] Inference engine: Makes reasonable context guesses

✅ **Performance**
- [ ] CPU overhead <5% for 30-second polls
- [ ] Execution time <2 seconds per detection cycle
- [ ] Memory usage <50MB for daemon

✅ **Quality**
- [ ] All detectors have test cases
- [ ] Error handling for edge cases (no window manager, process died, etc)
- [ ] JSON output validated with jq
- [ ] Documentation updated

✅ **Testing**
- [ ] Run on target system (Ubuntu Linux)
- [ ] Test with known projects (stock-v3, mallow-ai, etc)
- [ ] Verify accuracy on actual workflow
- [ ] Check fallback behavior when tools unavailable

### Important Context

**Why This Approach?**
User identified that old passive system only tracked terminal pwd. But they actually spend time in:
1. Browser (code reviews, docs)
2. Email (communications)
3. IDE (VS Code)
4. Terminal (coding, deployment)

Process-manager approach detects ALL of these by watching the active window, not trying to hardcode integrations for each tool.

**Key Insight**:
Instead of "is VS Code open?", ask "what does the user have active right now?" → check the foreground process → work backwards to context.

### Testing Workflow

Once you get the detectors working, test with this scenario:

```bash
# Terminal 1: Start daemon
work-daemon start

# Terminal 2: Jump around between contexts
cd ~/projects/stock-v3
# Should detect: stock-v3

firefox ~/projects/stock-v3/docs/
# Should detect: stock-v3 (from browser window title or path)

code ~/projects/mallow-ai
# Should detect: mallow-ai

# Check real-time detection
work-status-now
# Should show current context
```

### Files You'll Be Modifying

**Core Implementation**:
- `src/detectors/active-window.sh` - Partially started
- `src/detectors/process-tree.sh` - Skeleton
- `src/detectors/file-descriptors.sh` - Create new
- `src/detectors/inference.sh` - Create new

**Documentation** (update as you go):
- `memory-bank/progress.md` - Update status
- `memory-bank/activeContext.md` - Update blockers/accomplishments
- `ARCHITECTURE.md` - Already complete, reference only
- `README.md` - Already good, might need small updates

**Tests**:
- `tests/test-detection.sh` - Create comprehensive tests

### Questions for Next Phase (Phase 2)

Once Phase 1 is done, Phase 2 will need to answer:

1. **URL Mapping**: Which URLs identify which projects?
   - github.com/Mallow-Dev/stock-v3 → stock-v3
   - github.com/Mallow-Dev/mallow-ai → mallow-ai
   - docs.google.com/documents/XXXXX → which project?
   - internal.mallow.dev → which project?

2. **File Path Mapping**: ~/projects/X → project name? (mostly done, might need refinement)

3. **Confidence Scoring**: When signals conflict, which wins? (example: VS Code shows stock-v3, browser shows mallow-ai)

4. **Work Type Detection**: What signals indicate "code-review" vs "development" vs "documentation"?

### Escalation Points

If you hit blockers:
1. **Window manager issues**: Ask Renchey about their setup (X11, Wayland, etc)
2. **Performance problems**: Consider sampling instead of every 30s
3. **Process categorization gaps**: Need Renchey's input on unknown processes
4. **Edge cases**: Some scenarios might need special handling (containers, SSH, etc)

### Keep in Mind

- This is a **dev-tool** (could go external eventually)
- Align with `org-governance` standards for code
- Update memory bank as you go (progress.md change log)
- Test thoroughly before Phase 2
- Document edge cases and workarounds
- Keep it lightweight and portable (bash, standard Unix tools)

---

**Handoff Date**: 2025-11-30
**From**: Claude Code (Architecture)
**To**: GitHub Copilot (EOM - Implementation)
**Status**: Ready to implement Phase 1
**Next Review**: After Phase 1 completion
**Owner**: Work Context System Team

Good luck! This is a solid architecture with clear phases. Execute Phase 1 well, and Phase 2+ will be straightforward.
