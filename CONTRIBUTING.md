# Contributing to Work Context System

Thank you for your interest in contributing! This project follows a process-aware architecture designed to automatically detect developer work context.

## Development Setup

### Prerequisites

**Required**:
- Bash 4.0+
- `jq` (JSON processor)
- `xdotool` or `wmctrl` (window detection)
- Node.js 20+ (for API and web UI)

**Optional**:
- Docker (for containerized development)
- GitHub Codespaces (fully configured environment)

### Quick Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/renchey/work-context-system.git
   cd work-context-system
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Install system tools** (Linux):
   ```bash
   # Debian/Ubuntu
   sudo apt-get install jq xdotool wmctrl lsof

   # Fedora/RHEL
   sudo dnf install jq xdotool wmctrl lsof

   # Arch
   sudo pacman -S jq xdotool wmctrl lsof
   ```

4. **Verify setup**:
   ```bash
   # Test detectors
   ./tests/test-detection.sh

   # Check that detectors run <2s
   time bash src/detectors/active-window.sh
   ```

### Using GitHub Codespaces

Click the "Open in GitHub Codespaces" badge in README.md for a pre-configured environment with all dependencies installed.

## Project Structure

```
work-context-system/
├── src/
│   ├── detectors/          # System signal detection
│   ├── mappers/            # Signal → project/work-type mapping
│   ├── inference-combined.sh  # Context inference engine
│   ├── daemon/             # Background context monitoring
│   └── server/             # REST API
├── web/                    # Dashboard UI
├── tests/                  # Test suite
├── scripts/                # Utility scripts
├── memory-bank/            # Project documentation
└── docs/                   # Additional documentation
```

## Development Workflow

### 1. Choose Your Task

Check current work:
- `TASK-PHASE-1.md` - Phase 1 reference tasks
- `./scripts/task-status.sh` - Current task status
- `memory-bank/progress.md` - Latest progress

Open issues on GitHub or propose new features in discussions.

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming convention:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test improvements

### 3. Make Changes

Follow the existing patterns:

**For Detectors** (`src/detectors/`):
- Output JSON to stdout
- Use stderr for errors/debug
- Complete in <2 seconds
- Follow schema in detector tests

**For Mappers** (`src/mappers/`):
- Accept JSON stdin
- Output project/work-type candidates with confidence
- Include signal trace for transparency

**For API** (`src/server/`):
- RESTful endpoint design
- JSON responses
- Proper error handling

### 4. Run Tests

```bash
# Run all tests
./tests/test-detection.sh

# Test specific detector
bash src/detectors/active-window.sh | jq .

# Test mapper
echo '{"url": "github.com/renchey/stock-v3"}' | bash src/mappers/url-mapper.sh

# Test inference engine
bash src/inference-combined.sh
```

### 5. Update Documentation

If you've changed:
- **Architecture** → Update `ARCHITECTURE.md` or `PROJECT-ARCHITECTURE.md`
- **API** → Update `API-REFERENCE.md`
- **Setup** → Update this file
- **Progress** → Update `memory-bank/progress.md`

### 6. Commit Your Changes

Use descriptive commit messages:

```bash
git add .
git commit -m "feat: add email client detection support

- Added Thunderbird window detection
- Updated URL mapper for email domains
- Added tests for email context detection"
```

Commit message format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions/updates
- `refactor:` - Code refactoring
- `perf:` - Performance improvements

### 7. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Reference to related issues
- Test results
- Screenshots (if UI changes)

## Coding Standards

### Bash Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use meaningful variable names
- Add comments for complex logic
- Quote variables: `"${var}"` not `$var`
- Use `jq` for JSON processing

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect active window and extract metadata
get_active_window() {
    local window_id
    window_id=$(xdotool getactivewindow)
    
    local window_title
    window_title=$(xdotool getwindowname "${window_id}")
    
    echo "${window_title}"
}
```

### Node.js/JavaScript

- Use modern ES6+ syntax
- Async/await for promises
- Descriptive variable names
- Error handling with try/catch
- JSDoc comments for functions

**Example**:
```javascript
/**
 * Get current work context from state file
 * @returns {Promise<Object>} Current context object
 */
async function getCurrentContext() {
    try {
        const state = await fs.readFile(STATE_FILE, 'utf8');
        return JSON.parse(state);
    } catch (error) {
        throw new Error(`Failed to read context: ${error.message}`);
    }
}
```

### JSON Output Format

All detectors and mappers must output valid JSON:

```json
{
    "detector": "active-window",
    "timestamp": "2025-12-01T00:00:00Z",
    "data": {
        "window_title": "VS Code - stock-v3",
        "process_name": "code",
        "pid": 12345
    }
}
```

## Testing Requirements

### Detector Tests

- Must complete in <2 seconds
- Output valid JSON
- Handle missing dependencies gracefully
- Include error cases

### Mapper Tests

- Test confidence scoring
- Verify signal traces
- Test edge cases (unknown projects, etc.)
- Validate output schema

### Integration Tests

- End-to-end inference flow
- API endpoint testing
- UI functionality

## Performance Guidelines

- **Detector runtime**: <2 seconds per detector
- **Memory usage**: <50MB for daemon
- **API response**: <100ms for simple queries
- **Storage growth**: Keep JSONL append-only efficient

## Documentation Standards

- Use Markdown for all docs
- Include code examples
- Keep README.md up-to-date
- Document breaking changes
- Add inline comments for complex logic

## Memory Bank Updates

Update relevant memory bank files:
- `memory-bank/progress.md` - Track completed work
- `memory-bank/activeContext.md` - Current development focus
- `memory-bank/decisionLog.md` - Architectural decisions

## Code Review Process

PRs require:
1. All tests passing
2. Code review from maintainer
3. No merge conflicts
4. Updated documentation
5. Performance benchmarks (if applicable)

## Getting Help

- **Issues**: GitHub Issues for bugs and feature requests
- **Discussions**: GitHub Discussions for questions
- **Architecture**: Read `ARCHITECTURE.md` and `PROJECT-ARCHITECTURE.md`
- **Memory Bank**: Check `memory-bank/` for project context

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Recognition

Contributors are acknowledged in `CONTRIBUTORS.md` (append-only).

## Questions?

Feel free to open an issue or discussion if you're unsure about anything. We're here to help!
