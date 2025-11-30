#!/usr/bin/env bash
# process-tree.sh: Analyze running processes and categorize workload signals

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

# jq is required for JSON output
ensure_dependency "jq"
ensure_dependency "ps"

# Predefined categories we care about
categories=(browser editor nodejs python container git-ssh shell email chat http dev-server testing other)
declare -A category_counts
for category in "${categories[@]}"; do
    category_counts[$category]=0
done

# Helper: safe /proc reads
read_cmdline() {
    local pid=$1
    if [[ -r "/proc/$pid/cmdline" ]]; then
        local cmdline
        IFS= read -r -d '' cmdline <"/proc/$pid/cmdline" 2>/dev/null || true
        printf '%s' "${cmdline//$'\0'/ }"
        return 0
    fi
    printf ""
    return 0
}

get_mem_mb() {
    local rss_kb=$1
    if [[ -z "$rss_kb" ]]; then
        echo 0
        return
    fi
    echo $(( (rss_kb + 1023) / 1024 ))
}

is_cpu_intensive() {
    local cpu_raw=${1//[[:space:]]/}
    local integer_part=${cpu_raw%%.*}
    local fractional_part=0

    [[ -n "$integer_part" ]] || integer_part=0
    if [[ "$cpu_raw" == *.* ]]; then
        fractional_part=${cpu_raw#*.}
        [[ -n "$fractional_part" ]] || fractional_part=0
    fi

    if (( integer_part > 5 )); then
        return 0
    fi

    if (( integer_part == 5 )); then
        # treat any fractional component as exceeding the threshold
        if [[ "$fractional_part" =~ ^[0-9]+$ ]] && (( 10#$fractional_part > 0 )); then
            return 0
        fi
    fi

    return 1
}

is_mem_intensive() {
    local mem_mb=$1
    [[ "$mem_mb" -ge 100 ]]
}

categorize_process() {
    local name=${1,,}

    case "$name" in
        firefox|chrome|chromium|brave|vivaldi|edge|opera|safari)
            echo "browser"; return ;;
        code|code-insider*|antigravity|idea*|clion|pycharm|goland|vim|nvim|emacs|sublime_text)
            echo "editor"; return ;;
        node|nodejs|npm|npx)
            echo "nodejs"; return ;;
        python|python3|pip|pip3|ipython)
            echo "python"; return ;;
        docker|dockerd|podman|containerd|nerdctl)
            echo "container"; return ;;
        git|ssh|scp|sftp)
            echo "git-ssh"; return ;;
        bash|zsh|sh|fish|tmux|screen|wezterm|kitty)
            echo "shell"; return ;;
        thunderbird|evolution|mutt|alpine)
            echo "email"; return ;;
        slack|discord|telegram|teams|signal|mattermost|zoom|weechat)
            echo "chat"; return ;;
        curl|wget|httpie)
            echo "http"; return ;;
        webpack|vite|rollup|parcel|gulp|grunt)
            echo "dev-server"; return ;;
        jest|mocha|ava|pytest|go)
            echo "testing"; return ;;
        pytest|nose2|karma|cypress)
            echo "testing"; return ;;
    esac

    echo "other"
}

build_categories_json() {
    local first=true
    printf '{'
    for category in "${categories[@]}"; do
        local count=${category_counts[$category]:-0}
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s":%s' "$category" "$count"
    done
    printf '}'
}

intensive_buffer=""
buffered_limit=15
process_total=0
intensive_total=0

while read -r pid cpu rss comm; do
    [[ -n "$pid" ]] || continue
    ((process_total += 1))

    mem_mb=$(get_mem_mb "$rss")
    category=$(categorize_process "$comm")
    ((category_counts[$category] += 1))

    cpu_intensive=false
    if is_cpu_intensive "$cpu"; then
        cpu_intensive=true
    fi

    mem_intensive=false
    if is_mem_intensive "$mem_mb"; then
        mem_intensive=true
    fi

    if $cpu_intensive || $mem_intensive; then
        ((intensive_total += 1))
        cmd_emit=$(read_cmdline "$pid")
        if [[ $buffered_limit -gt 0 ]]; then
            sanitized=${cmd_emit//$'\t'/ }
            sanitized=${sanitized//$'\n'/ }
            printf -v intensive_line '%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "$comm" "$category" "$cpu" "$mem_mb" "$sanitized"
            intensive_buffer+="$intensive_line"
            buffered_limit=$((buffered_limit - 1))
        fi
    fi

done < <(ps -eo pid=,%cpu=,rss=,comm=)

categories_json=$(build_categories_json)
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build intensive JSON directly in bash (avoid extra jq call)
if [[ -n "$intensive_buffer" ]]; then
    intensive_json='['
    first_intensive=true
    while IFS=$'\t' read -r pid comm category cpu mem_mb cmdline; do
        [[ -n "$pid" ]] || continue
        if [ "$first_intensive" = true ]; then
            first_intensive=false
        else
            intensive_json+=','
        fi
        # Escape for JSON
        cmdline_escaped="${cmdline//\\/\\\\}"
        cmdline_escaped="${cmdline_escaped//\"/\\\"}"
        cmdline_escaped="${cmdline_escaped//$'\n'/\\n}"
        cmdline_escaped="${cmdline_escaped//$'\r'/\\r}"
        intensive_json+="{\"pid\":$pid,\"process_name\":\"$comm\",\"category\":\"$category\",\"cpu\":$cpu,\"mem_mb\":$mem_mb,\"cmdline\":\"$cmdline_escaped\"}"
    done <<< "$intensive_buffer"
    intensive_json+=']'
else
    intensive_json='[]'
fi

jq -n \
    --argjson processes "$process_total" \
    --argjson intensive "$intensive_total" \
    --arg timestamp "$timestamp" \
    --argjson categories "$categories_json" \
    --argjson intensive_details "$intensive_json" \
    '{
        processes: $processes,
        intensive_process_count: $intensive,
        categories: $categories,
        intensive_processes: $intensive_details,
        timestamp: $timestamp
    }'
