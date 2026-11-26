#!/bin/bash
# WezTerm の CMD+クリックから呼ばれ、ファイルを nvim で開く
# - herdr が動いていれば、ファイル名の新しいスペースを作ってそこで nvim を起動する
# - herdr が無ければ、従来どおり tmux の隣ペインで nvim を起動する
# Usage: open-in-nvim.sh <path> [line]
#   path が相対パスなら、フォーカス中のペインの cwd を基準に解決する

set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

path="${1:-}"
line="${2:-}"
[[ -n "$path" ]] || exit 1
[[ "$line" =~ ^[0-9]+$ ]] || line=""

herdr_running() {
  command -v herdr >/dev/null 2>&1 || return 1
  # grep -q の早期終了で pipefail に引っかからないよう、出力を受けてから判定する
  local status
  status="$(herdr status server 2>/dev/null || true)"
  [[ "$status" == *"status: running"* ]]
}

# フォーカス中のペインの cwd（実行中プロセスの cwd を優先）
focused_cwd() {
  if herdr_running; then
    herdr pane list 2>/dev/null |
      jq -r 'first(.result.panes[] | select(.focused) | (.foreground_cwd // .cwd)) // empty'
  elif command -v tmux >/dev/null 2>&1; then
    tmux display-message -p '#{pane_current_path}' 2>/dev/null || true
  fi
}

cwd="$(focused_cwd)"
[[ -d "$cwd" ]] || cwd="$HOME"

case "$path" in
  \~) path="$HOME" ;;
  \~/*) path="$HOME/${path#\~/}" ;;
  /*) ;;
  *) path="$cwd/$path" ;;
esac

# 存在しないパス（URL っぽいだけの文字列など）は無視する
[[ -f "$path" ]] || exit 0

nvim_cmd=(nvim)
[[ -n "$line" ]] && nvim_cmd+=("+$line")
nvim_cmd+=("$path")

if herdr_running; then
  pane_id="$(herdr workspace create --cwd "$cwd" --label "$(basename "$path")" --focus |
    jq -r '.result.root_pane.pane_id // empty')"
  [[ -n "$pane_id" ]] || exit 1
  # pane run はシェルにコマンド文字列を渡すので、引数をシェル用にクォートしてから渡す
  herdr pane run "$pane_id" "$(printf '%q ' "${nvim_cmd[@]}")" >/dev/null
elif command -v tmux >/dev/null 2>&1; then
  tmux split-window -h -c "$cwd" "${nvim_cmd[@]}"
fi
