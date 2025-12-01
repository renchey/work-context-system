#!/usr/bin/env bash
# ai-classifier.sh: Wrapper for AI-powered context classification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_CLASSIFIER="$SCRIPT_DIR/../ai/context-classifier.py"

# Input: JSON with window_title, process_name, cwd, etc
input=$(cat)

# Check if Python classifier exists
if [[ ! -x "$AI_CLASSIFIER" ]]; then
    # Fallback: pass through input unchanged with error flag
    echo "$input" | jq '. + {ai_error: "classifier not found or not executable"}'
    exit 0
fi

# Check if python3 is available
if ! command -v python3 >/dev/null 2>&1; then
    echo "$input" | jq '. + {ai_error: "python3 not available"}'
    exit 0
fi

# Run AI classifier
output=$(echo "$input" | python3 "$AI_CLASSIFIER" 2>/dev/null) || {
    # On error, pass through with error flag
    echo "$input" | jq '. + {ai_error: "classifier execution failed"}'
    exit 0
}

# Validate output is valid JSON
echo "$output" | jq . >/dev/null 2>&1 || {
    echo "$input" | jq '. + {ai_error: "invalid JSON output from classifier"}'
    exit 0
}

# Return the enriched JSON
echo "$output"
