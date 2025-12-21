#!/bin/zsh
tmux-current() {
  tmux new-session -As "$(basename "$PWD")"
}

ffileopen() {
  local file
  file=$(git ls-files | fzf)
  [ -n "$file" ] && code "$file"
}

fhistory(){
  fc -e - -n "$(history | tail -r | sed 's/ *[0-9]* *//' | fzf)"
}

tmux-cd() {
  echo "tmux-cd function is called."
  # 現在のディレクトリ名をセッション名にする
  local session_name
  session_name="$(basename "$PWD")"

  # tmux が起動していない場合
  if [[ -z "$TMUX" ]]; then
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux attach -t "$session_name"
    else
      tmux new-session -s "$session_name" -c "$PWD"
    fi
    return
  fi

  # tmux の中にいる場合
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$PWD"
    tmux switch-client -t "$session_name"
  fi
}
