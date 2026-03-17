#!/bin/bash
# 通知フック共通ライブラリ（source して使用）

NOTIFY_BUNDLE_ID="com.github.wez.wezterm"

# tmux ペインにフォーカスを切り替える
focus_tmux_pane() {
  local tmux_pane_dir="/tmp/claude-tmux-panes"
  local pane_id=""

  # セッション別ファイル → latest のフォールバックでペイン ID を取得
  if [[ -n "${CLAUDE_SESSION_ID:-}" ]] && [[ -f "${tmux_pane_dir}/${CLAUDE_SESSION_ID}" ]]; then
    pane_id=$(cat "${tmux_pane_dir}/${CLAUDE_SESSION_ID}")
  elif [[ -f "${tmux_pane_dir}/latest" ]]; then
    pane_id=$(cat "${tmux_pane_dir}/latest")
  fi

  # ペイン ID が取得できない場合はスキップ
  if [[ -z "${pane_id}" ]]; then
    return 0
  fi

  # セッション名を取得
  local session_name=""
  if [[ -n "${CLAUDE_SESSION_ID:-}" ]] && [[ -f "${tmux_pane_dir}/${CLAUDE_SESSION_ID}.session" ]]; then
    session_name=$(cat "${tmux_pane_dir}/${CLAUDE_SESSION_ID}.session")
  elif [[ -f "${tmux_pane_dir}/latest.session" ]]; then
    session_name=$(cat "${tmux_pane_dir}/latest.session")
  fi

  # ペインが存在するか確認してから切り替え
  if tmux display-message -t "${pane_id}" -p '' 2>/dev/null; then
    # WezTerm をフォアグラウンドにアクティベート
    osascript -e 'tell application "WezTerm" to activate' 2>/dev/null || true
    # 別セッションにいる場合はセッションを切り替え
    if [[ -n "${session_name}" ]]; then
      tmux switch-client -t "${session_name}" 2>/dev/null || true
    fi
    tmux select-window -t "${pane_id}" 2>/dev/null || true
    tmux select-pane -t "${pane_id}" 2>/dev/null || true
  fi
}

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
