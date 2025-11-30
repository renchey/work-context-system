#!/usr/bin/env bash
# file-path-to-project.sh: Map filesystem paths to project slugs

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

PROJECTS_ROOT=${PROJECTS_ROOT:-"$HOME/projects"}
declare -a PROJECT_HINTS=("stock-v3" "mallow-ai" "health-safety" "work-context-system")

if [[ -d "$PROJECTS_ROOT" ]]; then
    while IFS= read -r -d '' dir; do
        local_name=$(basename "$dir")
        [[ -n "$local_name" ]] && PROJECT_HINTS+=("$local_name")
    done < <(find "$PROJECTS_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
fi

input_path=${1:-""}

project="unknown"
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
        project="$candidate"
        confidence="$weight"
    fi
    add_signal "$reason"
}

resolve_path() {
    local path=$1
    if [[ -z "$path" ]]; then
        echo ""
        return
    fi
    readlink -f "$path" 2>/dev/null || echo "$path"
}

trim_git_suffix() {
    local path=$1
    path=${path%/.git}
    echo "$path"
}

resolved=$(resolve_path "$input_path")
resolved=$(trim_git_suffix "$resolved")

projects_root_real=$(resolve_path "$PROJECTS_ROOT")

if [[ -n "$projects_root_real" && "$resolved" == "$projects_root_real"* ]]; then
    subpath=${resolved#"$projects_root_real"/}
    candidate=${subpath%%/*}
    [[ -n "$candidate" ]] && set_candidate "$candidate" "0.95" "path:projects_root=$candidate"
fi

if [[ "$resolved" =~ /(stock-v3|mallow-ai|health-safety|work-context-system)(/|$) ]]; then
    set_candidate "${BASH_REMATCH[1]}" "0.8" "path:keyword=${BASH_REMATCH[1]}"
fi

basename_seg=$(basename "$resolved")
if [[ -n "$basename_seg" ]]; then
    for hint in "${PROJECT_HINTS[@]}"; do
        [[ -z "$hint" ]] && continue
        if [[ "${basename_seg,,}" == "${hint,,}" ]]; then
            set_candidate "$hint" "0.75" "path:basename=$hint"
            break
        fi
    done
fi

if [[ $project == "unknown" ]]; then
    depth_segment=$(basename "$(dirname "$resolved")")
    if [[ -n "$depth_segment" && "$depth_segment" != "." ]]; then
        set_candidate "$depth_segment" "0.4" "path:parent=$depth_segment"
    fi
fi

if (( ${#signals[@]} == 0 )); then
    signals_json='[]'
else
    signals_json=$(printf '%s\n' "${signals[@]}" | jq -R . | jq -s '.')
fi

jq -n \
    --arg project "$project" \
    --argjson confidence "$confidence" \
    --argjson signals "$signals_json" \
    '{project: $project, confidence: $confidence, signals: $signals}'
