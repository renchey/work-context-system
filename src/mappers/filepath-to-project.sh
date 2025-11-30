#!/usr/bin/env bash
# filepath-to-project.sh: Extract project from file paths

set -euo pipefail

filepath="${1:-}"
[ -z "$filepath" ] && { echo "{}"; exit 0; }

detect_project_from_path() {
    local path=$1
    
    # Direct project match
    if [[ "$path" =~ /projects/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    
    # Git repo detection
    if [[ "$path" =~ (stock-v3|mallow-ai|health-safety|mallow-agents) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    
    echo "unknown"
}

detect_file_type() {
    local path=$1
    
    [[ "$path" =~ \.(js|ts|tsx|jsx)$ ]] && echo "javascript" && return
    [[ "$path" =~ \.(py)$ ]] && echo "python" && return
    [[ "$path" =~ \.(sh|bash)$ ]] && echo "shell" && return
    [[ "$path" =~ \.(json|yaml|yml|toml)$ ]] && echo "config" && return
    [[ "$path" =~ \.(md|txt|doc)$ ]] && echo "documentation" && return
    [[ "$path" =~ \.git/ ]] && echo "git" && return
    
    echo "other"
}

project=$(detect_project_from_path "$filepath")
filetype=$(detect_file_type "$filepath")

jq -n \
    --arg filepath "$filepath" \
    --arg project "$project" \
    --arg filetype "$filetype" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
        filepath: $filepath,
        detected_project: $project,
        file_type: $filetype,
        confidence: (if $project == "unknown" then 0.5 else 0.95 end),
        timestamp: $timestamp
    }'
