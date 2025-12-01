# Work Context System - API Reference

## Base URL

```
http://localhost:3042/api
```

Default port is `3042`, configurable via `PORT` environment variable.

## Authentication

Currently no authentication required. API is designed for local-only access.

## Endpoints

### GET `/api/status`

Get the current work context in real-time.

**Response**

```json
{
  "project": "stock-v3",
  "work_type": "development",
  "confidence": 0.95,
  "signals": [
    {
      "source": "active_window",
      "data": "VS Code - stock-v3/src/api.ts"
    },
    {
      "source": "working_directory",
      "data": "/home/renchey/projects/stock-v3"
    }
  ],
  "daemon": {
    "running": true,
    "pid": "12345"
  },
  "timestamp": "2025-12-01T00:00:00.000Z"
}
```

**Fields**

- `project` (string) - Detected project name
- `work_type` (string) - Type of work being done
- `confidence` (number) - Confidence score (0.0-1.0)
- `signals` (array) - Raw signals contributing to detection
- `daemon` (object) - Daemon status information
- `timestamp` (string) - ISO 8601 timestamp

**Error Response**

```json
{
  "error": "No active context. Start daemon first."
}
```

**Status Codes**

- `200` - Success
- `500` - Server error

---

### GET `/api/timeline/:date`

Get context switches for a specific date or time range.

**Path Parameters**

- `date` (string) - Date filter
  - `today` - Today's events
  - `week` - Last 7 days
  - `YYYY-MM-DD` - Specific date

**Query Parameters**

- `limit` (number, optional) - Maximum events to return (default: 100)

**Example Request**

```
GET /api/timeline/today?limit=50
```

**Response**

```json
{
  "events": [
    {
      "type": "context_change",
      "timestamp": "2025-12-01T10:30:00.000Z",
      "data": {
        "project": "stock-v3",
        "work_type": "development",
        "confidence": 0.92
      }
    },
    {
      "type": "afk_detected",
      "timestamp": "2025-12-01T11:00:00.000Z",
      "data": {
        "duration_minutes": 15
      }
    }
  ],
  "total": 2,
  "date": "2025-12-01"
}
```

**Event Types**

- `context_change` - Project or work type switched
- `afk_detected` - User went AFK
- `afk_return` - User returned from AFK
- `work_note` - Manual annotation added

**Status Codes**

- `200` - Success
- `500` - Server error

---

### GET `/api/analytics`

Get aggregated work analytics and statistics.

**Response**

```json
{
  "total_events": 1247,
  "context_switches": 823,
  "afk_periods": 42,
  "projects": [
    {
      "name": "stock-v3",
      "count": 312
    },
    {
      "name": "work-context-system",
      "count": 245
    }
  ],
  "work_types": [
    {
      "type": "development",
      "count": 456
    },
    {
      "type": "code-review",
      "count": 234
    },
    {
      "type": "communication",
      "count": 133
    }
  ],
  "period": {
    "start": "2025-11-01T00:00:00.000Z",
    "end": "2025-12-01T00:00:00.000Z"
  }
}
```

**Fields**

- `total_events` (number) - Total events logged
- `context_switches` (number) - Number of context changes
- `afk_periods` (number) - Number of AFK periods detected
- `projects` (array) - Top 10 projects by frequency
- `work_types` (array) - Work types distribution
- `period` (object) - Time range of data

**Status Codes**

- `200` - Success
- `500` - Server error

---

### GET `/api/projects`

Get list of all detected projects with metadata.

**Response**

```json
{
  "projects": [
    {
      "name": "stock-v3",
      "first_seen": "2025-11-15T08:00:00.000Z",
      "last_seen": "2025-12-01T10:30:00.000Z",
      "switches": 312
    },
    {
      "name": "work-context-system",
      "first_seen": "2025-11-20T09:00:00.000Z",
      "last_seen": "2025-12-01T09:45:00.000Z",
      "switches": 245
    }
  ],
  "total": 2
}
```

**Fields**

- `name` (string) - Project name
- `first_seen` (string) - First detection timestamp
- `last_seen` (string) - Most recent detection
- `switches` (number) - Number of times switched to this project

**Sorting**

Projects sorted by `last_seen` (most recent first).

**Status Codes**

- `200` - Success
- `500` - Server error

---

### POST `/api/note`

Add a manual annotation/note to the current context.

**Request Body**

```json
{
  "note": "Starting code review for PR #123"
}
```

**Response**

```json
{
  "success": true,
  "timestamp": "2025-12-01T10:30:00.000Z"
}
```

**Validation**

- `note` field is required
- Returns `400` if note is missing

**Status Codes**

- `200` - Success
- `400` - Bad request (missing note)
- `500` - Server error

---

## Data Models

### Context Object

```typescript
interface Context {
  project: string;          // Project name (e.g., "stock-v3")
  work_type: string;        // Work type (e.g., "development")
  confidence: number;       // 0.0-1.0
  signals: Signal[];        // Contributing signals
  timestamp: string;        // ISO 8601
}
```

### Signal Object

```typescript
interface Signal {
  source: string;           // Signal source (e.g., "active_window")
  data: string | object;    // Signal data (varies by source)
}
```

### Event Object

```typescript
interface Event {
  type: string;             // Event type
  timestamp: string;        // ISO 8601
  data: object;            // Event-specific data
}
```

### Project Object

```typescript
interface Project {
  name: string;
  first_seen: string;       // ISO 8601
  last_seen: string;        // ISO 8601
  switches: number;
}
```

## Work Types

Standard work type classifications:

- `development` - Writing code, debugging
- `code-review` - PR reviews, code reading
- `communication` - Email, chat, meetings
- `operations` - Server management, deployments
- `documentation` - Writing docs, wikis
- `research` - Reading articles, documentation
- `planning` - Design, architecture discussions
- `testing` - Running tests, QA work
- `unknown` - Could not determine work type

## Error Handling

All endpoints return standard error format:

```json
{
  "error": "Error message describing the issue"
}
```

**Common Errors**

- `No active context. Start daemon first.` - Daemon not running
- `Note text required` - Missing required field
- `Invalid date format` - Malformed date parameter

## Rate Limiting

No rate limiting currently implemented. Designed for local-only access.

## CORS

CORS enabled for all origins to support web UI access.

## Data Storage

- **Sessions Log**: `~/.claude-work-data/sessions.jsonl`
- **Current State**: `~/.claude-work-data/context-state.json`

Data persists across API restarts.

## Performance

- Average response time: <50ms
- `/api/analytics` may take longer with large datasets (1000+ events)
- File-based storage limits scalability to ~100k events

## Client Examples

### JavaScript (Fetch)

```javascript
// Get current status
const response = await fetch('http://localhost:3042/api/status');
const status = await response.json();
console.log(`Currently working on: ${status.project}`);

// Get today's timeline
const timeline = await fetch('http://localhost:3042/api/timeline/today');
const data = await timeline.json();
console.log(`${data.total} events today`);

// Add note
await fetch('http://localhost:3042/api/note', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ note: 'Starting new feature' })
});
```

### curl

```bash
# Get current status
curl http://localhost:3042/api/status

# Get this week's timeline
curl http://localhost:3042/api/timeline/week

# Get analytics
curl http://localhost:3042/api/analytics

# Add note
curl -X POST http://localhost:3042/api/note \
  -H "Content-Type: application/json" \
  -d '{"note": "Starting code review"}'
```

## Webhooks

Not currently supported. Consider polling `/api/status` for real-time updates.

## WebSocket Support

Not currently supported. Use short polling (every 5-10 seconds) for real-time UI updates.

## Versioning

API is currently unversioned. Breaking changes will be communicated via release notes.
