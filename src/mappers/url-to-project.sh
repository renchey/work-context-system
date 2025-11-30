#!/usr/bin/env bash
# url-to-project.sh: Map URLs to project context

set -euo pipefail

url="${1:-}"
[ -z "$url" ] && { echo "{}"; exit 0; }

# URL pattern matching
detect_project_from_url() {
    local url=$1
    
    # GitHub
    [[ "$url" =~ github\.com/Mallow-Dev/stock-v3 ]] && echo "stock-v3" && return
    [[ "$url" =~ github\.com/Mallow-Dev/mallow-ai ]] && echo "mallow-ai" && return
    [[ "$url" =~ github\.com/Mallow-Dev/health-safety ]] && echo "health-safety" && return
    
    # Internal domains
    [[ "$url" =~ internal\.mallow\.dev/stock-v3 ]] && echo "stock-v3" && return
    [[ "$url" =~ docs\.mallow\.dev/stock-v3 ]] && echo "stock-v3" && return
    
    # Google Docs (need more sophisticated mapping)
    if [[ "$url" =~ docs\.google\.com/document ]]; then
        # Could store doc IDs → project mapping
        echo "unknown" && return
    fi
    
    # Generic fallback
    echo "unknown"
}

detect_work_type_from_url() {
    local url=$1
    
    [[ "$url" =~ /pull/ ]] && echo "code-review" && return
    [[ "$url" =~ /issues/ ]] && echo "issue-tracking" && return
    [[ "$url" =~ docs\.google\.com/document ]] && echo "documentation" && return
    [[ "$url" =~ docs\.google\.com/spreadsheets ]] && echo "analytics" && return
    
    echo "research"
}

project=$(detect_project_from_url "$url")
worktype=$(detect_work_type_from_url "$url")

jq -n \
    --arg url "$url" \
    --arg project "$project" \
    --arg worktype "$worktype" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
        url: $url,
        detected_project: $project,
        detected_worktype: $worktype,
        confidence: (if $project == "unknown" then 0.3 else 0.9 end),
        timestamp: $timestamp
    }'
