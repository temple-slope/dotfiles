#!/bin/bash
# Notification(permission_prompt) フック → "許可待ち" 通知

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/notify-common.sh"

project=$(cat | jq -r '.cwd | split("/") | last')
focus_tmux_pane
send_notification "${project}" "許可待ち" "Ping"
