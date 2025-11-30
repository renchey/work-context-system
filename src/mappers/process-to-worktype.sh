#!/usr/bin/env bash
# process-to-worktype.sh: Map process metadata to work type labels

set -euo pipefail

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_dependency() {
    local binary=$1
    if ! command_exists "$binary"; then
        echo "Error: missing dependency '$binary'" >&2
        exit 1
    fi
}

ensure_dependency "jq"
ensure_dependency "bc"

process_name=${1:-""}
cmdline=${2:-""}
window_title=${3:-""}

lower_process=${process_name,,}
lower_cmd=${cmdline,,}
lower_title=${window_title,,}

work_type="unknown"
confidence="0"
declare -a signals
signals=()

add_signal() {
    local signal=$1
    if [[ -n "$signal" ]]; then
        signals+=("$signal")
    fi
}

set_candidate() {
    local candidate=$1
    local weight=$2
    local reason=$3

    [[ -z "$candidate" || "$candidate" == "unknown" ]] && return

    if (( $(echo "$weight > $confidence" | bc -l) )); then
        work_type="$candidate"
        confidence="$weight"
    fi
    add_signal "$reason"
}

contains_any() {
    local haystack=$1
    shift
    for needle in "$@"; do
        [[ -z "$needle" ]] && continue
        if [[ $haystack == *"$needle"* ]]; then
            echo "$needle"
            return 0
        fi
    done
    return 1
}

if [[ -n "$lower_title" ]] && [[ $lower_title == *"pull request"* || $lower_title == *"github.com"* ]]; then
    set_candidate "code-review" "0.85" "title:github_pr"
fi

if match=$(contains_any "$lower_process" code code-insiders idea clion pycharm goland vim nvim emacs sublime); then
    set_candidate "development" "0.75" "process=$match"
fi

if match=$(contains_any "$lower_cmd" "npm run dev" "npm start" "yarn dev" "pipenv run" "uvicorn" "gunicorn" "node server" "cargo run"); then
    set_candidate "development" "0.7" "cmd=$match"
fi

if match=$(contains_any "$lower_cmd" "npm test" "pytest" "tox" "cargo test" "go test" "jest" "cypress" "karma" "vitest"); then
    set_candidate "testing" "0.8" "cmd=$match"
fi

if match=$(contains_any "$lower_cmd" ssh kubectl terraform ansible helm kubernetes docker-compose); then
    set_candidate "ops-deployment" "0.75" "cmd=$match"
fi

if match=$(contains_any "$lower_process" thunderbird outlook evolution mutt alpine); then
    set_candidate "communication" "0.7" "process=$match"
fi

if match=$(contains_any "$lower_process" slack discord telegram signal teams zoom weechat mattermost); then
    set_candidate "communication" "0.65" "process=$match"
fi

if [[ -z "$lower_process" && -z "$lower_cmd" && -z "$lower_title" ]]; then
    set_candidate "unknown" "0" "no_signals"
fi

if [[ $work_type == "unknown" ]]; then
    if match=$(contains_any "$lower_process" firefox chrome chromium brave safari arc); then
        set_candidate "research" "0.55" "browser=$match"
    fi
fi

if [[ $work_type == "unknown" && $lower_title == *"docs.google.com"* ]]; then
    set_candidate "documentation" "0.5" "title=docs"
fi

if (( ${#signals[@]} == 0 )); then
    signals_json='[]'
else
    signals_json=$(printf '%s\n' "${signals[@]}" | jq -R . | jq -s '.')
fi

jq -n \
    --arg work_type "$work_type" \
    --argjson confidence "$confidence" \
    --argjson signals "$signals_json" \
    '{work_type: $work_type, confidence: $confidence, signals: $signals}'
