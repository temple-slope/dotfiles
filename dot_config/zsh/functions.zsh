tmux-current() {
  tmux new-session -As "$(basename "$PWD")"
}

ffileopen() {
  local file=$(git ls-files | fzf)
  [ -n "$file" ] && code "$file"
}

fhistory(){
  fc -e - -n "$(history | tail -r | sed 's/ *[0-9]* *//' | fzf)"
}

tmux-split-4() {
  tmux split-window -h \; \
       split-window -v \; \
       select-pane -L \; \
       split-window -v \; \
       select-pane -t 0
}

cz-all-add(){
  chezmoi status | awk '{ $1=""; print substr($0,2) }' | while IFS= read -r file; do
    [ -n "$file" ] && chezmoi add "$file"
  done
}
