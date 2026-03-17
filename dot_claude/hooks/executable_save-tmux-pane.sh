#!/bin/bash
# SessionStart フック - Claude Code 起動時の tmux ペイン情報を保存
# 固定パスのファイルに書き込み、他のフックから読み込む

set -euo pipefail

TMUX_PANE_DIR="/tmp/claude-tmux-panes"

# tmux 外で実行されている場合はスキップ
if [[ -z "${TMUX:-}" ]]; then
  cat > /dev/null
  exit 0
fi

# stdin から JSON を読み取り
HOOK_INPUT=$(cat)
SESSION_ID=$(echo "${HOOK_INPUT}" | jq -r '.session_id // empty')

mkdir -p "${TMUX_PANE_DIR}"

# tmux セッション名を取得
TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")

# セッション別にペイン ID とセッション名を保存
if [[ -n "${SESSION_ID}" ]]; then
  echo "${TMUX_PANE}" > "${TMUX_PANE_DIR}/${SESSION_ID}"
  echo "${TMUX_SESSION}" > "${TMUX_PANE_DIR}/${SESSION_ID}.session"
fi

# 最新のペインとしても保存（フォールバック用）
echo "${TMUX_PANE}" > "${TMUX_PANE_DIR}/latest"
echo "${TMUX_SESSION}" > "${TMUX_PANE_DIR}/latest.session"
