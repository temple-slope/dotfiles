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
