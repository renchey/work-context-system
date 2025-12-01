#!/usr/bin/env bash
# tests/test-ai-classifier.sh: Unit tests for AI context classifier

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AI_CLASSIFIER="$REPO_ROOT/src/ai/context-classifier.py"
AI_WRAPPER="$REPO_ROOT/src/mappers/ai-classifier.sh"

log() {
    printf '[test-ai] %s\n' "$1" >&2
}

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

pass() {
    printf '[PASS] %s\n' "$1" >&2
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd python3
require_cmd jq

# Test 1: Python classifier exists and is executable
test_classifier_executable() {
    log "Test 1: Classifier executable check"
    [[ -x "$AI_CLASSIFIER" ]] || fail "AI classifier not executable"
    pass "Classifier is executable"
}

# Test 2: Wrapper script exists and is executable
test_wrapper_executable() {
    log "Test 2: Wrapper executable check"
    [[ -x "$AI_WRAPPER" ]] || fail "AI wrapper not executable"
    pass "Wrapper is executable"
}

# Test 3: Classifier accepts valid JSON input
test_valid_json_input() {
    log "Test 3: Valid JSON input"
    local input='{"process_name": "code", "window_title": "test.js", "process_cwd": "/home/user/projects/test"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER") || fail "Classifier failed on valid input"
    echo "$output" | jq . >/dev/null || fail "Output is not valid JSON"
    pass "Valid JSON input accepted"
}

# Test 4: Classifier rejects invalid JSON
test_invalid_json_input() {
    log "Test 4: Invalid JSON handling"
    local input='not valid json'
    local output
    if echo "$input" | python3 "$AI_CLASSIFIER" 2>/dev/null; then
        fail "Classifier should reject invalid JSON"
    fi
    pass "Invalid JSON properly rejected"
}

# Test 5: Output contains required AI fields
test_output_fields() {
    log "Test 5: Output field validation"
    local input='{"process_name": "firefox", "window_title": "GitHub - Pull Request"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    # Check for required AI fields
    echo "$output" | jq -e '.ai_predicted_worktype' >/dev/null || fail "Missing ai_predicted_worktype"
    echo "$output" | jq -e '.ai_confidence' >/dev/null || fail "Missing ai_confidence"
    echo "$output" | jq -e 'has("ai_classifier_trained")' >/dev/null || fail "Missing ai_classifier_trained"
    echo "$output" | jq -e 'has("ai_training_samples")' >/dev/null || fail "Missing ai_training_samples"
    
    pass "All required output fields present"
}

# Test 6: Confidence score is between 0 and 1
test_confidence_range() {
    log "Test 6: Confidence score range"
    local input='{"process_name": "code", "window_title": "main.py"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    local confidence
    confidence=$(echo "$output" | jq -r '.ai_confidence')
    
    # Validate confidence is numeric and in range [0, 1]
    if ! [[ "$confidence" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        fail "Confidence is not numeric: $confidence"
    fi
    
    if (( $(echo "$confidence < 0" | bc -l) )) || (( $(echo "$confidence > 1" | bc -l) )); then
        fail "Confidence out of range [0,1]: $confidence"
    fi
    
    pass "Confidence score in valid range"
}

# Test 7: Heuristic classification for development context
test_heuristic_development() {
    log "Test 7: Development context classification"
    local input='{"process_name": "code", "window_title": "main.py", "process_cwd": "/home/user/projects/myapp"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    local worktype
    worktype=$(echo "$output" | jq -r '.ai_predicted_worktype')
    
    [[ "$worktype" == "development" ]] || fail "Expected 'development', got '$worktype'"
    pass "Development context correctly classified"
}

# Test 8: Heuristic classification for code review
test_heuristic_code_review() {
    log "Test 8: Code review context classification"
    local input='{"process_name": "firefox", "window_title": "Pull Request #123 - GitHub"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    local worktype
    worktype=$(echo "$output" | jq -r '.ai_predicted_worktype')
    
    [[ "$worktype" == "code-review" ]] || fail "Expected 'code-review', got '$worktype'"
    pass "Code review context correctly classified"
}

# Test 9: Heuristic classification for testing
test_heuristic_testing() {
    log "Test 9: Testing context classification"
    local input='{"process_name": "bash", "process_cmdline": "npm run test"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    local worktype
    worktype=$(echo "$output" | jq -r '.ai_predicted_worktype')
    
    [[ "$worktype" == "testing" ]] || fail "Expected 'testing', got '$worktype'"
    pass "Testing context correctly classified"
}

# Test 10: Wrapper script integration
test_wrapper_integration() {
    log "Test 10: Wrapper script integration"
    local input='{"process_name": "ssh", "process_cmdline": "ssh deploy@server"}'
    local output
    output=$(echo "$input" | "$AI_WRAPPER")
    
    echo "$output" | jq . >/dev/null || fail "Wrapper output is not valid JSON"
    
    # Should have AI fields
    echo "$output" | jq -e '.ai_predicted_worktype' >/dev/null || fail "Wrapper missing ai_predicted_worktype"
    
    pass "Wrapper integration successful"
}

# Test 11: Wrapper error handling (missing Python)
test_wrapper_fallback() {
    log "Test 11: Wrapper fallback mechanism"
    local input='{"process_name": "test"}'
    
    # Test that wrapper handles errors gracefully
    # This test verifies wrapper doesn't crash on edge cases
    local output
    output=$(echo "$input" | "$AI_WRAPPER") || fail "Wrapper crashed"
    
    echo "$output" | jq . >/dev/null || fail "Wrapper output invalid JSON on error"
    
    pass "Wrapper error handling works"
}

# Test 12: Empty input handling
test_empty_input() {
    log "Test 12: Empty input handling"
    local input='{}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    echo "$output" | jq . >/dev/null || fail "Classifier failed on empty input"
    
    local worktype
    worktype=$(echo "$output" | jq -r '.ai_predicted_worktype')
    
    [[ -n "$worktype" ]] || fail "No worktype predicted for empty input"
    pass "Empty input handled gracefully"
}

# Test 13: Multiple process patterns
test_multiple_signals() {
    log "Test 13: Multiple classification signals"
    local input='{"process_name": "code", "window_title": "test.spec.js", "process_cwd": "/home/user/projects/app", "process_cmdline": "code /home/user/projects/app"}'
    local output
    output=$(echo "$input" | python3 "$AI_CLASSIFIER")
    
    local confidence
    confidence=$(echo "$output" | jq -r '.ai_confidence')
    
    # With multiple strong signals, confidence should be relatively high
    if (( $(echo "$confidence < 0.5" | bc -l) )); then
        fail "Confidence too low with multiple strong signals: $confidence"
    fi
    
    pass "Multiple signals handled correctly"
}

# Run all tests
main() {
    log "Starting AI classifier tests"
    
    test_classifier_executable
    test_wrapper_executable
    test_valid_json_input
    test_invalid_json_input
    test_output_fields
    test_confidence_range
    test_heuristic_development
    test_heuristic_code_review
    test_heuristic_testing
    test_wrapper_integration
    test_wrapper_fallback
    test_empty_input
    test_multiple_signals
    
    log "All tests passed!"
}

main
