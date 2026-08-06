#!/bin/bash
# Stop フック → "タスク完了" 通知
# Stop は stdout に有効な JSON を要求するため、最後に空オブジェクトを返す

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/notify-common.sh"

project=$(cat | jq -r '.cwd | split("/") | last')
send_notification "${project}" "タスク完了" "Glass"

echo '{}'
