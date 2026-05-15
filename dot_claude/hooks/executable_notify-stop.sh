#!/bin/bash
# Stop フック → "タスク完了" 通知

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/notify-common.sh"

project=$(cat | jq -r '.cwd | split("/") | last')
send_notification "${project}" "タスク完了" "Glass"
