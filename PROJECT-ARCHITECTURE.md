# Work Context System - Project Architecture

## Overview

Zero-friction work context tracking for chaotic developers that automatically detects what you're working on across all tools—terminal, IDE, browser, email—without any manual logging or activation.

## Architecture Philosophy

**Process-Manager Aware Detection** - Universal context detection that works with ANY tool by monitoring system-level activity rather than app-specific integrations.

## System Components

### 1. Detection Layer (`src/detectors/`)

**Purpose**: Gather raw system signals about user activity

- **Active Window Detector** - Monitors which process has focus (xdotool/wmctrl)
- **Process Tree Analyzer** - Tracks resource-consuming processes
- **File Descriptor Inspector** - Identifies active files/networks (lsof, /proc/[pid]/fd)
- **Working Directory Scanner** - Determines where processes are running

**Output**: JSON signals with process metadata, window titles, file paths, network connections

### 2. Mapping Layer (`src/mappers/`)

**Purpose**: Transform raw signals into meaningful project/work-type candidates

- **URL Mapper** - github.com → project name, domain → work type
- **Path Mapper** - File paths → project directory inference
- **Process Mapper** - Process names → work type classification
- **Confidence Scoring** - Multi-signal aggregation with weighted scores

**Output**: Project/work-type candidates with confidence levels and signal traces

### 3. Inference Engine (`src/inference-combined.sh`)

**Purpose**: Stitch detector + mapper outputs into final context determination

**Algorithm**:
1. Collect all detector outputs (active window, process tree, file descriptors)
2. Run mapping heuristics on each signal
3. Aggregate confidence scores across signals
4. Select highest-confidence project + work-type combination
5. Include signal trace for transparency

**Output**: Final context with project, work_type, confidence, and signal breakdown

### 4. Daemon Layer (`src/daemon/`)

**Purpose**: Continuous monitoring and state management

- **Context Poller** - Runs inference engine every N seconds
- **Change Detection** - Identifies meaningful context switches
- **Session Logger** - Appends events to `~/.claude-work-data/sessions.jsonl`
- **State Manager** - Maintains current context in `context-state.json`

### 5. API Layer (`src/server/api.js`)

**Purpose**: REST API for querying work context and analytics

**Endpoints**:
- `GET /api/status` - Current work context
- `GET /api/timeline/:date` - Context switches for a date
- `GET /api/analytics` - Work analytics summary
- `GET /api/projects` - List all projects
- `POST /api/note` - Add manual annotation

### 6. Web UI (`web/`)

**Purpose**: Real-time dashboard for work context visualization

- **Live Status** - Current project, work type, duration
- **Timeline View** - Context switches over time
- **Analytics** - Project frequency, work type distribution
- **Project Management** - Track and analyze work patterns

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      USER ACTIVITY                           │
│  (Terminal, IDE, Browser, Email, etc.)                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   DETECTION LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Active   │  │ Process  │  │   File   │  │ Working  │   │
│  │ Window   │  │   Tree   │  │Descriptor│  │Directory │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │ JSON Signals
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    MAPPING LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │   URL    │  │   Path   │  │ Process  │                  │
│  │  Mapper  │  │  Mapper  │  │  Mapper  │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└──────────────────────┬──────────────────────────────────────┘
                       │ Project/WorkType Candidates
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  INFERENCE ENGINE                            │
│         Confidence Scoring + Signal Aggregation              │
└──────────────────────┬──────────────────────────────────────┘
                       │ Final Context
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    DAEMON LAYER                              │
│     Context Polling → Change Detection → Session Logging     │
└──────────────────────┬──────────────────────────────────────┘
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
    ┌─────────────┐         ┌─────────────┐
    │  API Layer  │         │   Web UI    │
    │(REST Queries)         │ (Dashboard) │
    └─────────────┘         └─────────────┘
```

## Technology Stack

**Core**:
- **Runtime**: Bash 4.0+ (detection/mapping), Node.js 20+ (API/UI)
- **Data Format**: JSONL for session logs, JSON for state
- **Storage**: File-based (`~/.claude-work-data/`)

**Detection**:
- `xdotool` / `wmctrl` - Window manager integration
- `/proc` filesystem - Process introspection
- `lsof` - File descriptor analysis
- `ps` - Process tree inspection

**API**:
- Express.js - REST API framework
- CORS - Cross-origin resource sharing
- File system - Direct JSONL reading

**Web UI**:
- Vanilla JavaScript - No framework overhead
- Fetch API - REST client
- HTML/CSS - Simple dashboard

## Key Design Decisions

### Why Process-Manager Approach?

❌ **App-specific integrations** - Brittle, not portable, maintenance hell  
✅ **Process-manager awareness** - Universal, self-healing, works with any tool

Whether you use Chrome or Firefox, Thunderbird or Gmail, VS Code or Vim—the system detects your actual activity.

### Why JSONL for Session Logs?

- **Append-only** - Safe for concurrent writes
- **Streaming-friendly** - Parse line-by-line without loading entire file
- **Time-series native** - Each event is timestamped
- **Human-readable** - Easy to inspect and debug

### Why File-Based Storage?

- **Simplicity** - No database setup required
- **Portability** - Works anywhere with filesystem access
- **Privacy** - All data stays local
- **Backupability** - Standard file backup tools work

### Why Bash for Detection?

- **System-level access** - Direct /proc filesystem access
- **Universal availability** - Works on any Linux system
- **Process efficiency** - Native system calls, minimal overhead
- **Script composability** - Easy to chain detectors and mappers

## Phase Implementation Plan

### Phase 1: Core Detection (Complete)
✅ Active window detection  
✅ Process tree analysis  
✅ File descriptor inspection  
✅ JSON output per spec  
✅ <2s runtime enforcement

### Phase 2: Project Mapping (Complete)
✅ URL → Project mapping  
✅ File path → Project mapping  
✅ Process name → Work type mapping  
✅ Confidence scoring with signal traces  
✅ Inference engine integration

### Phase 3: Daemon Integration (In Progress)
🚧 Process-aware daemon with context polling  
🚧 Session logger with JSONL append  
🚧 Change detection and event filtering  
🚧 State management with context-state.json

### Phase 4: Output & UI (Planned)
📋 Web dashboard with live status  
📋 Timeline visualization  
📋 Analytics and work pattern analysis  
📋 Manual annotation support

## Performance Targets

- **Detection latency**: <2 seconds per inference cycle
- **Memory footprint**: <50MB for daemon process
- **Storage growth**: ~1MB per day of active use
- **API response time**: <100ms for status queries

## Security & Privacy

- **Local-only**: All data stays on user's machine
- **No network**: No telemetry or external dependencies
- **No credentials**: No sensitive data collection
- **User control**: Easy to inspect, modify, or delete data

## Extension Points

### Custom Mappers
Add new mapping heuristics in `src/mappers/` following the pattern:
- Input: JSON signal from detector
- Output: Project/work-type candidates with confidence scores

### Custom Work Types
Extend work type classifications in process/URL mappers:
- `development` - Writing code
- `code-review` - PR reviews, code reading
- `communication` - Email, chat, meetings
- `operations` - Server management, deployments
- `documentation` - Writing docs, wikis

### Custom Projects
Projects auto-discovered from:
- Git repository names in file paths
- GitHub/GitLab URLs
- Working directory names
- Manual annotations via API

## Testing Strategy

- **Unit tests**: Individual detector/mapper validation
- **Integration tests**: End-to-end inference engine verification
- **Performance tests**: Runtime enforcement (<2s per cycle)
- **Schema validation**: JSON output conformance

## Future Enhancements

- **AFK detection** - Idle time tracking with comeback detection
- **Cognitive load inference** - Multi-task detection
- **Background process awareness** - Docker, dev servers
- **Integration exports** - Slack status, calendar blocking
- **Machine learning** - Pattern learning for better inference
