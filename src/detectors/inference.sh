#!/usr/bin/env bash
# inference.sh: Combine detector signals to infer current work context

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

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE_WINDOW_SCRIPT="$ROOT_DIR/detectors/active-window.sh"
PROCESS_TREE_SCRIPT="$ROOT_DIR/detectors/process-tree.sh"
FD_SCRIPT="$ROOT_DIR/detectors/file-descriptors.sh"
MAPPERS_DIR="$ROOT_DIR/mappers"
URL_MAPPER="$MAPPERS_DIR/url-to-project.sh"
FILE_MAPPER="$MAPPERS_DIR/file-path-to-project.sh"
WORKTYPE_MAPPER="$MAPPERS_DIR/process-to-worktype.sh"

for script in "$ACTIVE_WINDOW_SCRIPT" "$PROCESS_TREE_SCRIPT" "$FD_SCRIPT" "$URL_MAPPER" "$FILE_MAPPER" "$WORKTYPE_MAPPER"; do
    if [ ! -f "$script" ]; then
        echo "Error: detector script '$script' missing" >&2
        exit 1
    fi
    if [ ! -x "$script" ]; then
        chmod +x "$script"
    fi
done

run_detector() {
    local script=$1
    if [ ! -x "$script" ]; then
        chmod +x "$script"
    fi
    "$script"
}

aw_json=$(run_detector "$ACTIVE_WINDOW_SCRIPT")
pt_json=$(run_detector "$PROCESS_TREE_SCRIPT")
fd_json=$(run_detector "$FD_SCRIPT")

a_pid=$(jq -r '.pid // 0' <<<"$aw_json")
a_process=$(jq -r '.process_name // "unknown"' <<<"$aw_json")
a_title=$(jq -r '.window_title // ""' <<<"$aw_json")
a_cwd=$(jq -r '.process_cwd // ""' <<<"$aw_json")
a_cmd=$(jq -r '.process_cmdline // ""' <<<"$aw_json")
fd_project=$(jq -r '.file_descriptors.project_paths[0] // ""' <<<"$fd_json")
fd_repo=$(jq -r '.file_descriptors.git_repos[0] // ""' <<<"$fd_json")
fd_url=$(jq -r '.file_descriptors.open_urls[0] // ""' <<<"$fd_json")
fd_conn=$(jq -r '.file_descriptors.network_connections[0] // ""' <<<"$fd_json")

calc() {
    echo "$1" | bc -l
}

min_float() {
    awk -v a="$1" -v b="$2" 'BEGIN {print (a < b) ? a : b}'
}

cap_one() {
    local value=$1
    if (( $(echo "$value > 1" | bc -l) )); then
        echo "1"
    else
        echo "$value"
    fi
}

declare -a signals
add_signal() {
    local signal=$1
    if [[ -n "$signal" ]]; then
        signals+=("$signal")
    fi
}

declare -A project_scores
best_project="unknown"
best_project_score="0"

add_project_candidate() {
    local candidate=$1
    local weight=${2:-0}

    [[ -z "$candidate" || "$candidate" == "unknown" ]] && return

    local current=${project_scores[$candidate]:-0}
    local new_score
    new_score=$(calc "$current + $weight")
    project_scores[$candidate]="$new_score"

    if (( $(echo "$new_score > $best_project_score" | bc -l) )); then
        best_project="$candidate"
        best_project_score="$new_score"
    fi
}

append_signals_from_mapper() {
    local mapper_json=$1
    mapfile -t mapper_signals < <(jq -r '.signals[]?' <<<"$mapper_json") || true
    for entry in "${mapper_signals[@]:-}"; do
        add_signal "$entry"
    done
}

add_project_candidate_from_json() {
    local mapper_json=$1
    local candidate
    local weight
    candidate=$(jq -r '.project // "unknown"' <<<"$mapper_json")
    weight=$(jq -r '.confidence // 0' <<<"$mapper_json")
    append_signals_from_mapper "$mapper_json"
    add_project_candidate "$candidate" "$weight"
}

legacy_infer_project() {
    local cwd=$1
    local project_path=$2
    local repo=$3

    if [[ -n "$project_path" ]]; then
        basename "$project_path"
        return
    fi

    if [[ -n "$cwd" && "$cwd" == *"/projects/"* ]]; then
        echo "$cwd" | awk -F'/projects/' '{print $2}' | cut -d'/' -f1
        return
    fi

    if [[ -n "$repo" ]]; then
        basename "${repo%/.git}"
        return
    fi

    echo "unknown"
}

legacy_infer_work_type() {
    local process_name=$1
    local window_title=$2
    local cmdline=$3
    local url=$4

    local process_lower=${process_name,,}
    local title_lower=${window_title,,}
    local cmd_lower=${cmdline,,}
    local url_lower=${url,,}

    if [[ $title_lower == *"github.com"* || $url_lower == *"github.com"* ]]; then
        echo "code-review"
        return
    fi

    if [[ $process_lower == *"code"* || $title_lower == *"workspace"* ]]; then
        echo "development"
        return
    fi

    if [[ $process_lower == *"firefox"* || $process_lower == *"chrome"* ]]; then
        echo "research"
        return
    fi

    if [[ $cmd_lower == *"npm test"* || $cmd_lower == *"pytest"* ]]; then
        echo "testing"
        return
    fi

    if [[ $cmd_lower == *"ssh"* || $title_lower == *"ssh"* ]]; then
        echo "ops-deployment"
        return
    fi

    echo "unknown"
}

cwd_mapper_json=$("$FILE_MAPPER" "$a_cwd")
fd_path_mapper_json=$("$FILE_MAPPER" "$fd_project")
fd_repo_mapper_json=$("$FILE_MAPPER" "$fd_repo")
url_mapper_json=$("$URL_MAPPER" "$fd_url" "$a_title")

add_project_candidate_from_json "$cwd_mapper_json"
add_project_candidate_from_json "$fd_path_mapper_json"
add_project_candidate_from_json "$fd_repo_mapper_json"
add_project_candidate_from_json "$url_mapper_json"

project="$best_project"
if [[ "$project" == "unknown" ]]; then
    project=$(legacy_infer_project "$a_cwd" "$fd_project" "$fd_repo")
fi

worktype_mapper_json=$("$WORKTYPE_MAPPER" "$a_process" "$a_cmd" "$a_title")
work_type=$(jq -r '.work_type // "unknown"' <<<"$worktype_mapper_json")
worktype_conf=$(jq -r '.confidence // 0' <<<"$worktype_mapper_json")
append_signals_from_mapper "$worktype_mapper_json"

if [[ "$work_type" == "unknown" ]]; then
    fallback_worktype=$(legacy_infer_work_type "$a_process" "$a_title" "$a_cmd" "$fd_url")
    if [[ -n "$fallback_worktype" && "$fallback_worktype" != "unknown" ]]; then
        work_type="$fallback_worktype"
        worktype_conf="0.3"
        add_signal "legacy_worktype=$work_type"
    fi
fi

confidence="0.2"

if [[ -n "$a_cwd" ]]; then
    add_signal "cwd=$a_cwd"
    confidence=$(calc "$confidence + 0.1")
fi

if [[ -n "$fd_project" ]]; then
    add_signal "project_path=$fd_project"
    confidence=$(calc "$confidence + 0.1")
fi

if [[ -n "$fd_url" ]]; then
    add_signal "url=$fd_url"
    confidence=$(calc "$confidence + 0.05")
fi

if [[ -n "$fd_conn" ]]; then
    add_signal "network=$fd_conn"
    confidence=$(calc "$confidence + 0.05")
fi

confidence=$(calc "$confidence + $(min_float "$best_project_score" "0.6")")
confidence=$(calc "$confidence + $(min_float "$worktype_conf" "0.4")")

if [[ "$project" != "unknown" && "$work_type" != "unknown" ]]; then
    confidence=$(calc "$confidence + 0.1")
fi

if (( ${#signals[@]} >= 4 )); then
    confidence=$(calc "$confidence + 0.05")
fi

confidence=$(cap_one "$confidence")

if (( ${#signals[@]} == 0 )); then
    signals_json='[]'
else
    signals_json=$(printf '%s\n' "${signals[@]}" | jq -R . | jq -s '.')
fi

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n \
    --arg project "$project" \
    --arg work_type "$work_type" \
    --argjson confidence "$confidence" \
    --argjson active_window "$aw_json" \
    --argjson process_tree "$pt_json" \
    --argjson file_descriptors "$fd_json" \
    --argjson signals "$signals_json" \
    --arg timestamp "$timestamp" \
    '{
        project: $project,
        work_type: $work_type,
        confidence: $confidence,
        signals: $signals,
        timestamp: $timestamp,
        detectors: {
            active_window: $active_window,
            process_tree: $process_tree,
            file_descriptors: $file_descriptors
        }
    }'
