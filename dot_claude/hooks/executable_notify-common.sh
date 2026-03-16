#!/bin/bash
# 通知フック共通ライブラリ（source して使用）

# ターミナルアプリの Bundle ID を自動検出
get_terminal_bundle_id() {
  # __CFBundleIdentifier が設定されていれば直接使用（最も確実）
  if [[ -n "${__CFBundleIdentifier}" ]]; then
    echo "${__CFBundleIdentifier}"
    return
  fi

  # TERM_PROGRAM 環境変数から検出（フォールバック）
  case "${TERM_PROGRAM}" in
    "Apple_Terminal") echo "com.apple.Terminal" ;;
    "iTerm.app")      echo "com.googlecode.iterm2" ;;
    "ghostty")        echo "com.mitchellh.ghostty" ;;
    "WarpTerminal")   echo "dev.warp.Warp-Stable" ;;
    "WezTerm")        echo "com.github.wez.wezterm" ;;
    *)
      # プロセスツリーから検出
      local pid parent comm
      pid=$$
      while [[ "${pid}" -ne 1 ]] 2>/dev/null; do
        parent=$(ps -p "${pid}" -o ppid= 2>/dev/null | tr -d ' ') || break
        [[ -z "${parent}" ]] && break
        comm=$(ps -p "${parent}" -o comm= 2>/dev/null)
        case "${comm}" in
          *Terminal*)  echo "com.apple.Terminal"; return ;;
          *iTerm*)     echo "com.googlecode.iterm2"; return ;;
          *Cursor*)    echo "com.todesktop.230313mzl4w4u92"; return ;;
          *Code*)      echo "com.microsoft.VSCode"; return ;;
          *ghostty*)   echo "com.mitchellh.ghostty"; return ;;
          *warp*)      echo "dev.warp.Warp-Stable"; return ;;
          *wezterm*)   echo "com.github.wez.wezterm"; return ;;
          *)           ;;
        esac
        pid="${parent}"
      done
      echo ""
      ;;
  esac
}

NOTIFY_BUNDLE_ID=$(get_terminal_bundle_id)

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
