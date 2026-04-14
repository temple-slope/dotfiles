#!/bin/bash
# 通知フック共通ライブラリ（source して使用）

send_notification() {
  local project="$1"
  local message="$2"
  local sound="$3"

  terminal-notifier -title "Claude Code" -subtitle "${project}" -message "${message}" -sound "${sound}" -activate "com.github.wez.wezterm"
}
