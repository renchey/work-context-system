# Product Context

## Problem We're Solving

### User Pain Points

**Renchey's Actual Workflow**:
- Works on 13+ projects in `~/projects/`
- Jumps between them spontaneously (stock-v3 → mallow-ai → health-safety)
- Long background processes running (docker, npm dev servers, tests)
- Frequent urgent interruptions
- Unexpected AFK periods (PC breaks, hardware issues, calls)
- Takes 22-minute break to fix PC, system should auto-detect
- Doesn't know how much time is spent on each project/context

### Why Existing Solutions Fail

**Manual Time Tracking**
- Too much friction (stop, log time, comment, resume)
- Requires discipline
- Doesn't match chaotic workflow
- People cheat/skip logging

**Terminal-Only Tracking**
- Can't detect browser work (code reviews, docs)
- Can't detect email work (communications)
- Can't detect IDE work when terminal is inactive
- Misses 70% of actual context

**App-Specific Integrations**
- VS Code extension? Doesn't work when not coding
- Browser extension? Only works in that browser
- Email API? Only works with that email client
- Users change tools → system breaks

### The Key Insight

**The user's actual context is in the active process**, not in their declarations:
- Active window has focus
- That process has a PID
- That PID has working directory
- Working directory reveals project
- Foreground process reveals work type (coding, review, email, etc)

No app needs to know about our system. We just **watch what's already happening**.

## Market Opportunity

### Internal (Mallow-Dev)

**Benefits**:
- Understand time allocation across projects
- Detect over-commitment (too many background tasks)
- Automated work timeline (who did what when)
- Context switching awareness
- Burndown tracking (tasks → context switches → time)

**Users**: Renchey, future team members, agents

### External (Dev Tool Market)

**Product**: "Context" - Passive work context tracker for developers

**Target Market**: Developers with chaotic workflows
- Freelancers juggling multiple clients
- Startup founders (many concurrent projects)
- Open source maintainers
- DevRel engineers (context switching constantly)

**Value Proposition**:
- See where your time really goes
- Automatic context tracking (zero friction)
- Cross-tool awareness (browser, IDE, terminal, email)
- No explicit logging required
- Works with tools you already use

**Potential Monetization**:
- Free tier: Basic tracking + export
- Pro tier: Analytics, timeline visualization, integrations
- Enterprise: Team dashboards, billing integration, audit logs

**Competitive Advantage**:
- Process-manager approach (tool-agnostic)
- No extensions/integrations required
- Just watches what's happening
- Works on any system (Linux, macOS with some adaptation)

## User Stories

### User Story 1: Understand Time Allocation
> As a freelancer juggling 3 clients, I want to know how much time I actually spent on each client's work, so I can bill accurately and spot capacity issues.

**Current**: Manual time tracking (error-prone, forgotten)
**With System**: Automatic context detection shows time spent per project

### User Story 2: Prevent Over-Commitment
> As a developer with urgent incoming work, I want the system to warn me when I'm already juggling too many background processes, so I don't take on more than I can handle.

**Current**: Mental model (often wrong, leads to overcommit)
**With System**: System sees actual cognitive load (docker containers + npm processes + tests) and warns when taking new work

### User Story 3: Understand Context Switching Cost
> As a team lead, I want to see how much context switching happens per person, so I can protect focus time and improve delivery.

**Current**: No visibility
**With System**: Timeline shows context switches, duration per context, impact on deliverables

### User Story 4: Recover from Interruptions
> As a developer interrupted by a hardware issue, I want the system to know I was gone and auto-track the break, so my timeline is accurate.

**Current**: Manual logging ("brb for 22 mins")
**With System**: Auto-detects AFK period, logs it, resumes tracking when active again

## Market Position

| Aspect | Competitor | Our Solution |
|--------|-----------|--------------|
| **Tool Integration** | Hardcoded (one per tool) | Process-aware (any tool) |
| **Friction** | Manual + extension install | Zero friction (daemon) |
| **Coverage** | Terminal only | Terminal + browser + IDE + email |
| **Portability** | High friction to switch tools | Tools don't matter |
| **Privacy** | Cloud-dependent | Local only |

## MVP Scope

**In Scope**:
- Passive context detection (no user activation)
- Process-manager awareness (active window, resource usage)
- Project/URL → Project context mapping
- Real-time status display
- Timeline analysis
- Sessions.jsonl logging

**Out of Scope** (Future):
- GUI/visualization (CLI only)
- Cloud sync
- Mobile app
- Machine learning models
- Real-time integrations (Slack, calendar)
- Multi-user/team features

## Success Indicators

**For Internal Use**:
- [ ] Used daily by Renchey
- [ ] Accurate context detection >95%
- [ ] Provides insight into time allocation
- [ ] Helps manage over-commitment

**For External Product**:
- [ ] GitHub stars >100
- [ ] Regular contributor interest
- [ ] Use in other organizations
- [ ] Positive testimonials
- [ ] Potential sponsorship/funding interest

## Monetization Strategy

**Phase 1** (Current): Open source, internal tool
**Phase 2** (Future): Consider:
- Sponsorship/Patreon model
- Enterprise support/consulting
- Add-on tools (analytics, integrations)
- Training/documentation

---

**Created**: 2025-11-30
**Updated**: 2025-11-30
**Owner**: Work Context System Team
