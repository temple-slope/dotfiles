#!/bin/bash
# PermissionRequest フック → "許可待ち" 通知
# 承認判断に干渉しないよう stdout には何も出力しない

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/notify-common.sh"

project=$(cat | jq -r '.cwd | split("/") | last')
send_notification "${project}" "許可待ち" "Ping"
