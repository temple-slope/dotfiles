#!/bin/bash
# 通知フック共通ライブラリ（source して使用）

send_notification() {
  local project="$1"
  local message="$2"
  local sound="$3"

  if [[ -n "${NOTIFY_BUNDLE_ID}" ]]; then
    terminal-notifier -title "Claude Code" -subtitle "${project}" -message "${message}" -sound "${sound}" -activate "${NOTIFY_BUNDLE_ID}"
  else
    terminal-notifier -title "Claude Code" -subtitle "${project}" -message "${message}" -sound "${sound}"
  fi
}
