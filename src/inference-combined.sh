#!/usr/bin/env bash
# inference-combined.sh: Enhanced inference combining all mappers

set -euo pipefail

# Run all detectors
active_window=$(./src/detectors/active-window.sh 2>/dev/null || echo "{}")
process_tree=$(./src/detectors/process-tree.sh 2>/dev/null || echo "{}")
file_descriptors=$(./src/detectors/file-descriptors.sh 2>/dev/null || echo "{}")

# Extract signals
pid=$(echo "$active_window" | jq -r '.pid // null')
process_name=$(echo "$active_window" | jq -r '.process_name // ""')
window_title=$(echo "$active_window" | jq -r '.window_title // ""')
process_cwd=$(echo "$active_window" | jq -r '.process_cwd // ""')

# Run mappers
url_inference=$(echo "$window_title" | ./src/mappers/url-to-project.sh)
path_inference=$(echo "$process_cwd" | ./src/mappers/filepath-to-project.sh)
worktype=$(echo "$active_window" | ./src/mappers/worktype-classifier.sh)

# Run AI classifier for additional signal
ai_classification=$(echo "$active_window" | ./src/mappers/ai-classifier.sh 2>/dev/null || echo "{}")

# Combine signals for final project determination
project=""
project_confidence=0

url_project=$(echo "$url_inference" | jq -r '.detected_project // ""')
url_conf=$(echo "$url_inference" | jq -r '.confidence // 0')

path_project=$(echo "$path_inference" | jq -r '.detected_project // ""')
path_conf=$(echo "$path_inference" | jq -r '.confidence // 0')

# Take highest confidence signal
if (( $(echo "$url_conf > $path_conf" | bc -l) )); then
    project="$url_project"
    project_confidence="$url_conf"
else
    project="$path_project"
    project_confidence="$path_conf"
fi

# Fallback if both unknown
if [[ "$project" == "unknown" ]]; then
    project=""
    project_confidence="0"
fi

classified_worktype=$(echo "$worktype" | jq -r '.classified_worktype // "unknown"')
worktype_confidence=$(echo "$worktype" | jq -r '.worktype_confidence // 0')

# Extract AI predictions
ai_worktype=$(echo "$ai_classification" | jq -r '.ai_predicted_worktype // ""')
ai_confidence=$(echo "$ai_classification" | jq -r '.ai_confidence // 0')

# Use AI as fallback if heuristic confidence is low
if (( $(echo "$worktype_confidence < 0.5" | bc -l) )) && [[ -n "$ai_worktype" ]] && [[ "$ai_worktype" != "unknown" ]]; then
    if (( $(echo "$ai_confidence > $worktype_confidence" | bc -l) )); then
        classified_worktype="$ai_worktype"
        worktype_confidence="$ai_confidence"
    fi
fi

jq -n \
    --arg project "$project" \
    --arg worktype "$classified_worktype" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg pc "$project_confidence" \
    --arg wc "$worktype_confidence" \
    --arg pid "$pid" \
    --arg process_name "$process_name" \
    --arg window_title "$window_title" \
    --arg ai_worktype "$ai_worktype" \
    --arg ai_conf "$ai_confidence" \
    '{
        project: (if $project == "" then null else $project end),
        work_type: $worktype,
        project_confidence: ($pc | tonumber),
        worktype_confidence: ($wc | tonumber),
        overall_confidence: (($pc | tonumber) * ($wc | tonumber)),
        signals: {
            pid: ($pid | tonumber? // null),
            process_name: $process_name,
            window_title: $window_title
        },
        ai_fallback: {
            predicted_worktype: (if $ai_worktype == "" then null else $ai_worktype end),
            confidence: ($ai_conf | tonumber)
        },
        timestamp: $timestamp
    }'
