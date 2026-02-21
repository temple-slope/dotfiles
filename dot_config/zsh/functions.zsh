#!/bin/zsh
tmux-current() {
  tmux new-session -As "$(basename "$PWD")"
}

ffileopen() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repo" >&2
    return 1
  fi
  local file
  file=$(git ls-files | fzf)
  [ -n "$file" ] && code "$file"
}

fhistory(){
  fc -e - -n "$(history | tail -r | sed 's/ *[0-9]* *//' | fzf)"
}

tmux-cd() {
  # 引数でディレクトリを指定（省略時は現在のディレクトリ）
  local target_dir="${1:-$PWD}"

  # ディレクトリの存在確認と絶対パスへの変換
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist" >&2
    return 1
  fi
  target_dir="$(cd "$target_dir" && pwd)"

  # ディレクトリ名をセッション名にする
  local session_name
  session_name="$(basename "$target_dir")"

  # tmux が起動していない場合
  if [[ -z "$TMUX" ]]; then
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux attach -t "$session_name"
    else
      tmux new-session -s "$session_name" -c "$target_dir"
    fi
    return
  fi

  # tmux の中にいる場合
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$target_dir"
    tmux switch-client -t "$session_name"
  fi
}
