#!/usr/bin/env bash
# worktype-classifier.sh: Classify work type from multiple signals

set -euo pipefail

# Input: JSON with window_title, process_name, cwd, etc
input=$(cat)

classify_worktype() {
    local window_title=$(echo "$input" | jq -r '.window_title // ""')
    local process=$(echo "$input" | jq -r '.process_name // ""')
    local cwd=$(echo "$input" | jq -r '.process_cwd // ""')
    local cmdline=$(echo "$input" | jq -r '.process_cmdline // ""')
    
    # Code review signals
    if [[ "$window_title" =~ pull|/pr/ ]] || [[ "$window_title" =~ "code review" ]]; then
        echo "code-review"
        return
    fi
    
    # Development signals
    if [[ "$process" =~ "code|vim|nvim|emacs" ]] && [[ "$cwd" =~ "projects" ]]; then
        echo "development"
        return
    fi
    
    # Testing signals
    if [[ "$cmdline" =~ "npm test|npm run test|jest|mocha|pytest" ]]; then
        echo "testing"
        return
    fi
    
    # Deployment/ops signals
    if [[ "$process" =~ "ssh|scp|docker" ]] || [[ "$cmdline" =~ "deploy|docker|kubernetes" ]]; then
        echo "ops-deployment"
        return
    fi
    
    # Documentation signals
    if [[ "$window_title" =~ "docs|README|wiki" ]] || [[ "$process" =~ "code" ]] && [[ "$cwd" =~ "docs" ]]; then
        echo "documentation"
        return
    fi
    
    # Communication signals
    if [[ "$process" =~ "thunderbird|mail|slack|discord" ]]; then
        echo "communication"
        return
    fi
    
    # Research/browsing
    if [[ "$process" =~ "firefox|chrome|chromium|safari" ]]; then
        echo "research"
        return
    fi
    
    echo "unknown"
}

confidence_score() {
    local worktype=$1
    case "$worktype" in
        code-review|development|testing|ops-deployment|communication)
            echo "0.85"
            ;;
        documentation|research)
            echo "0.70"
            ;;
        *)
            echo "0.30"
            ;;
    esac
}

worktype=$(classify_worktype)
confidence=$(confidence_score "$worktype")

echo "$input" | jq \
    --arg worktype "$worktype" \
    --arg confidence "$confidence" \
    '. + {
        classified_worktype: $worktype,
        worktype_confidence: ($confidence | tonumber)
    }'
