#!/usr/bin/env bash
# file-descriptors.sh: Inspect open files/network sockets for context clues

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

PROJECTS_ROOT="${HOME}/projects"

declare -A git_repos_map
declare -A project_paths_map
declare -A urls_map
declare -A network_map
notes=()

extract_remote_endpoint() {
    local entry=$1
    local cleaned=${entry#TCP }
    cleaned=${cleaned#UDP }
    cleaned=${cleaned%% *}
    cleaned=${cleaned%%(*}
    cleaned=${cleaned// /}

    if [[ "$cleaned" == *"->"* ]]; then
        echo "${cleaned##*->}"
        return 0
    fi

    # LISTEN sockets only have local endpoint
    echo "${cleaned%%->*}"
}

record_git_repo() {
    local path=$1
    [[ -z "$path" ]] && return
    if [[ "$path" == *.git ]]; then
        git_repos_map["$path"]=1
        return
    fi
    if [[ "$path" == *"/.git"* ]]; then
        git_repos_map["${path%%/.git*}/.git"]=1
    fi
}

record_project_path() {
    local path=$1
    [[ -z "$path" ]] && return
    if [[ -n "$PROJECTS_ROOT" && "$path" == "$PROJECTS_ROOT"/* ]]; then
        local rest=${path#${PROJECTS_ROOT}/}
        local project=${rest%%/*}
        if [[ -n "$project" ]]; then
            project_paths_map["$PROJECTS_ROOT/$project"]=1
        fi
    fi
}

maybe_record_url() {
    local target=$1
    [[ -z "$target" ]] && return
    if [[ "$target" =~ ^https?:// ]]; then
        urls_map["$target"]=1
        return
    fi

    # Promote known domains from bare host names
    local host=${target%%:*}
    case "$host" in
        *.github.com|github.com|gitlab.com|bitbucket.org|notion.so|docs.google.com|linear.app)
            urls_map["https://$host"]=1
            ;;
    esac
}

record_network() {
    local entry=$1
    local remote
    remote=$(extract_remote_endpoint "$entry")
    [[ -z "$remote" ]] && return
    # Skip wildcard entries
    if [[ "$remote" == "*:*" ]]; then
        return
    fi
    network_map["$remote"]=1
    maybe_record_url "$remote"
}

process_fd_target() {
    local target=$1
    [[ -z "$target" ]] && return

    if [[ "$target" == TCP* || "$target" == UDP* ]]; then
        record_network "$target"
        return
    fi

    record_git_repo "$target"
    record_project_path "$target"
    maybe_record_url "$target"
}

collect_from_lsof() {
    if ! command_exists lsof; then
        notes+=("lsof not available; detector ran in degraded mode")
        return 1
    fi

    # Limit to current user to avoid permission denials
    if ! lsof -nP -F pn | head -n1 >/dev/null 2>&1; then
        notes+=("lsof returned no data (insufficient permissions?)")
        return 1
    fi

    local current_pid=""
    while IFS= read -r line; do
        case "$line" in
            p*)
                current_pid=${line#p}
                ;;
            n*)
                local name=${line#n}
                [[ -z "$name" ]] && continue
                process_fd_target "$name"
                ;;
        esac
    done < <(lsof -nP -F pn 2>/dev/null)

    return 0
}

collect_from_proc() {
    local proc_root="/proc"
    shopt -s nullglob
    for fd_path in $proc_root/[0-9]*/fd/*; do
        local target
        target=$(readlink "$fd_path" 2>/dev/null || true)
        [[ -z "$target" ]] && continue
        process_fd_target "$target"
    done
    shopt -u nullglob
}

if ! collect_from_lsof; then
    collect_from_proc
fi

to_json_array() {
    local map_name=$1
    eval "local -A temp_ref=\"(\${$map_name[@]})\""
    local keys
    keys=$(eval "echo \${!$map_name[@]}")
    if [[ -z "$keys" ]]; then
        echo '[]'
        return
    fi
    eval "printf '%s\\0' \${!$map_name[@]}" | jq -Rs 'split("\u0000") | map(select(length>0)) | sort | unique'
}

repos_json=$(to_json_array git_repos_map)
projects_json=$(to_json_array project_paths_map)
urls_json=$(to_json_array urls_map)
network_json=$(to_json_array network_map)
notes_json='[]'
if ((${#notes[@]} > 0)); then
    notes_json=$(printf '%s\0' "${notes[@]}" | jq -Rs 'split("\u0000") | map(select(length>0))')
fi

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n \
    --arg timestamp "$timestamp" \
    --argjson git_repos "$repos_json" \
    --argjson project_paths "$projects_json" \
    --argjson open_urls "$urls_json" \
    --argjson network_connections "$network_json" \
    --argjson notes "$notes_json" \
    '{
        file_descriptors: {
            git_repos: $git_repos,
            open_urls: $open_urls,
            project_paths: $project_paths,
            network_connections: $network_connections
        },
        notes: (if $notes == [] then null else $notes end),
        timestamp: $timestamp
    }'
