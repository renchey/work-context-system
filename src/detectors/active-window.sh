#!/usr/bin/env bash
# active-window.sh: Detect what window/process has focus right now

set -euo pipefail

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

emit_error_json() {
    local message=$1
    jq -n --arg error "$message" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
        pid: null,
        process_name: "unknown",
        window_title: "",
        process_cwd: null,
        process_cmdline: "",
        timestamp: $timestamp,
        error: $error
    }'
}

ensure_dependency() {
    local binary=$1
    if ! command_exists "$binary"; then
        echo "Error: missing dependency '$binary'" >&2
        emit_error_json "Required dependency '$binary' is not installed"
        exit 1
    fi
}

# jq is mandatory for JSON output
ensure_dependency "jq"

normalize_window_id() {
    local raw_id=$1
    raw_id=${raw_id#0x}
    echo "${raw_id,,}"
}

detect_active_window() {
    local window_id=""
    local pid=""
    local window_title=""
    local window_class=""

    if command_exists xdotool; then
        window_id=$(xdotool getactivewindow 2>/dev/null || true)
        if [ -n "$window_id" ]; then
            pid=$(xdotool getwindowpid "$window_id" 2>/dev/null || true)
            window_title=$(xdotool getwindowname "$window_id" 2>/dev/null || true)
            window_class=$(xdotool getwindowclassname "$window_id" 2>/dev/null || true)
        fi
    fi

    if [ -z "$window_id" ] && command_exists xprop && command_exists wmctrl; then
        local active_hex
        active_hex=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $NF}' || true)
        if [[ "$active_hex" =~ ^0x[0-9a-fA-F]+$ ]]; then
            window_id="$active_hex"
            local normalized_id
            normalized_id=$(normalize_window_id "$active_hex")

            pid=$(wmctrl -lp | awk -v id="$normalized_id" '{
                window=$1; window=toupper(window); gsub("^0X", "", window)
                if (tolower(window) == id) { print $3; exit }
            }')

            window_title=$(wmctrl -lp | awk -v id="$normalized_id" '{
                window=$1; window=toupper(window); gsub("^0X", "", window)
                if (tolower(window) == id) {
                    $1=""; $2=""; $3=""; sub(/^\s+/, ""); print;
                    exit
                }
            }')
        fi
    fi

    if [ -z "$window_title" ] && command_exists wmctrl; then
        window_title=$(wmctrl -l 2>/dev/null | head -n1 | cut -d" " -f5- || true)
    fi

    if [ -z "$pid" ]; then
        pid=$(ps -o ppid= -p "$$" 2>/dev/null | awk '{print $1}' || true)
    fi

    printf '%s\t%s\t%s\t%s\n' "$window_id" "$pid" "$window_title" "$window_class"
}

get_process_name() {
    local pid=$1
    if [[ -z "$pid" || "$pid" == "0" ]]; then
        echo "unknown"
        return
    fi

    if [[ -r "/proc/$pid/comm" ]]; then
        tr -d '\n' <"/proc/$pid/comm"
        return
    fi

    ps -p "$pid" -o comm= 2>/dev/null | tr -d '\n' || echo "unknown"
}

get_process_cwd() {
    local pid=$1
    if [[ -n "$pid" && -L "/proc/$pid/cwd" ]]; then
        readlink -f "/proc/$pid/cwd" 2>/dev/null && return
    fi
    echo ""
}

get_process_cmdline() {
    local pid=$1
    if [[ -n "$pid" && -r "/proc/$pid/cmdline" ]]; then
        tr '\0' ' ' <"/proc/$pid/cmdline" | sed 's/ *$//' && return
    fi
    ps -p "$pid" -o args= 2>/dev/null | sed 's/^ *//'
}

main() {
    local window_id pid window_title window_class
    IFS=$'\t' read -r window_id pid window_title window_class < <(detect_active_window)

    local process_name process_cwd process_cmdline
    process_name=$(get_process_name "$pid")
    process_cwd=$(get_process_cwd "$pid")
    process_cmdline=$(get_process_cmdline "$pid")

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    jq -n \
        --arg pid "${pid:-}" \
        --arg process_name "${process_name:-unknown}" \
        --arg window_title "${window_title:-}" \
        --arg window_class "${window_class:-}" \
        --arg process_cwd "${process_cwd:-}" \
        --arg process_cmdline "${process_cmdline:-}" \
        --arg timestamp "$timestamp" \
        '{
            pid: ($pid | tonumber? // null),
            process_name: $process_name,
            window_title: $window_title,
            window_class: $window_class,
            process_cwd: (if $process_cwd == "" then null else $process_cwd end),
            process_cmdline: $process_cmdline,
            timestamp: $timestamp
        }'
}

main "$@"
