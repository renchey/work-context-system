#!/usr/bin/env bash
# tests/test-detection.sh: Validate detectors and inference pipeline

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DETECTORS_DIR="$REPO_ROOT/src/detectors"
MAPPERS_DIR="$REPO_ROOT/src/mappers"
URL_MAPPER="$MAPPERS_DIR/url-to-project.sh"
FILE_MAPPER="$MAPPERS_DIR/file-path-to-project.sh"
WORKTYPE_MAPPER="$MAPPERS_DIR/process-to-worktype.sh"

log() {
    printf '[test] %s\n' "$1" >&2
}

fail() {
    printf '[fail] %s\n' "$1" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_cmd jq

run_and_validate_json() {
    local label=$1
    local script=$2
    log "Running $label ($script)"
    local output
    output=$("$script") || fail "$label failed"
    echo "$output" | jq . >/dev/null || fail "$label emitted invalid JSON"
    echo "$output"
}

assert_field_present() {
    local json=$1
    local field=$2
    local value
    value=$(jq -r "$field // empty" <<<"$json")
    [[ -n "$value" ]] || fail "Missing expected field $field"
}

check_active_window() {
    local json=$1
    jq -e '((.pid | type) == "number") or (.pid == null)' <<<"$json" >/dev/null || fail "pid should be number or null"
    jq -e '.timestamp | test("^20[0-9]{2}-")' <<<"$json" >/dev/null || fail "timestamp format invalid"
}

check_process_tree() {
    local json=$1
    jq -e '.processes | type == "number" and . >= 1' <<<"$json" >/dev/null || fail "process count invalid"
    jq -e '.categories | type == "object"' <<<"$json" >/dev/null || fail "categories missing"
}

check_file_descriptors() {
    local json=$1
    jq -e '.file_descriptors | type == "object"' <<<"$json" >/dev/null || fail "file_descriptors missing"
}

check_inference() {
    local json=$1
    jq -e '.confidence | type == "number" and (. >= 0 and . <= 1)' <<<"$json" >/dev/null || fail "confidence out of range"
    jq -e '.work_type | type == "string"' <<<"$json" >/dev/null || fail "work_type missing"
}

measure_performance() {
    local script=$1
    local label=$2
    log "Measuring performance for $label"
    local elapsed
    elapsed=$(TIMEFORMAT=%R; { time "$script" >/dev/null; } 2>&1)
    awk -v t="$elapsed" 'BEGIN { if (t > 2) exit 1 }' || fail "$label exceeded 2s (t=${elapsed}s)"
}

main() {
    log "Starting detection test suite"

    aw_output=$(run_and_validate_json "active-window" "$DETECTORS_DIR/active-window.sh")
    check_active_window "$aw_output"

    pt_output=$(run_and_validate_json "process-tree" "$DETECTORS_DIR/process-tree.sh")
    check_process_tree "$pt_output"

    fd_output=$(run_and_validate_json "file-descriptors" "$DETECTORS_DIR/file-descriptors.sh")
    check_file_descriptors "$fd_output"

    inf_output=$(run_and_validate_json "inference" "$DETECTORS_DIR/inference.sh")
    check_inference "$inf_output"

    test_mappers

    measure_performance "$DETECTORS_DIR/active-window.sh" "active-window"
    measure_performance "$DETECTORS_DIR/process-tree.sh" "process-tree"

    log "All detectors validated successfully"
}

test_mappers() {
    log "Validating mapping utilities"

    local url_output
    url_output=$("$URL_MAPPER" "https://github.com/Mallow-Dev/stock-v3/pull/123" "Pull Request #123 - GitHub")
    jq -e '.project | type == "string"' <<<"$url_output" >/dev/null || fail "url mapper missing project"
    jq -e '.confidence | type == "number"' <<<"$url_output" >/dev/null || fail "url mapper confidence invalid"

    local tmp_root
    tmp_root=$(mktemp -d)
    mkdir -p "$tmp_root/focus-proj/src"
    local file_output
    file_output=$(PROJECTS_ROOT="$tmp_root" "$FILE_MAPPER" "$tmp_root/focus-proj/src/index.js")
    jq -e '.project == "focus-proj"' <<<"$file_output" >/dev/null || fail "file-path mapper failed"
    rm -rf "$tmp_root"

    local work_output
    work_output=$("$WORKTYPE_MAPPER" "code" "code ~/projects/focus-proj" "VS Code - focus-proj")
    jq -e '.work_type == "development"' <<<"$work_output" >/dev/null || fail "process-to-worktype mapper failed"
}

main "$@"
