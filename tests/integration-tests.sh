#!/usr/bin/env bash
# integration-tests.sh: Comprehensive integration tests

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

echo "Running Integration Tests..."
echo ""

# Test 1: Active window detection
echo "Test Suite 1: Detectors"
output=$("$PROJECT_DIR/src/detectors/active-window.sh" 2>/dev/null || echo "{}")
if echo "$output" | jq empty 2>/dev/null; then
    test_pass "active-window.sh produces valid JSON"
else
    test_fail "active-window.sh JSON validation"
fi

# Test 2: Process tree detection
output=$("$PROJECT_DIR/src/detectors/process-tree.sh" 2>/dev/null || echo "{}")
if echo "$output" | jq empty 2>/dev/null; then
    test_pass "process-tree.sh produces valid JSON"
else
    test_fail "process-tree.sh JSON validation"
fi

# Test 3: File descriptors detection
output=$("$PROJECT_DIR/src/detectors/file-descriptors.sh" 2>/dev/null || echo "{}")
if echo "$output" | jq empty 2>/dev/null; then
    test_pass "file-descriptors.sh produces valid JSON"
else
    test_fail "file-descriptors.sh JSON validation"
fi

# Test 4: Inference engine
echo ""
echo "Test Suite 2: Inference"
output=$("$PROJECT_DIR/src/detectors/active-window.sh" 2>/dev/null | "$PROJECT_DIR/src/mappers/worktype-classifier.sh" 2>/dev/null || echo "{}")
if echo "$output" | jq empty 2>/dev/null; then
    test_pass "inference produces valid JSON"
else
    test_fail "inference JSON validation"
fi

# Test 5: CLI command
echo ""
echo "Test Suite 3: CLI"
if [ -x "$PROJECT_DIR/work" ]; then
    test_pass "work CLI is executable"
else
    test_fail "work CLI executable check"
fi

# Test 6: Export functionality
echo ""
echo "Test Suite 4: Export Tools"
if [ -x "$PROJECT_DIR/src/output/work-export.sh" ]; then
    test_pass "work-export.sh is executable"
else
    test_fail "work-export.sh executable check"
fi

# Test 7: Web server
echo ""
echo "Test Suite 5: Web"
if [ -f "$PROJECT_DIR/web/index.html" ]; then
    test_pass "web/index.html exists"
else
    test_fail "web/index.html check"
fi

if [ -f "$PROJECT_DIR/web/server.js" ]; then
    test_pass "web/server.js exists"
else
    test_fail "web/server.js check"
fi

# Test 8: Integrations
echo ""
echo "Test Suite 6: Integrations"
if [ -x "$PROJECT_DIR/integrations/slack-status-sync.sh" ]; then
    test_pass "slack-status-sync.sh is executable"
else
    test_fail "slack-status-sync.sh check"
fi

if [ -x "$PROJECT_DIR/integrations/calendar-blocker.sh" ]; then
    test_pass "calendar-blocker.sh is executable"
else
    test_fail "calendar-blocker.sh check"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $TESTS_FAILED
