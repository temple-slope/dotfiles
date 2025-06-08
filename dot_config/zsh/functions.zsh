tmux-current() {
  tmux new-session -As "$(basename "$PWD")"
}

ffileopen() {
  local file=$(git ls-files | fzf)
  [ -n "$file" ] && code "$file"
}

fhistory(){
  # Show command history in reverse order using builtin fc to support both macOS
  # and GNU environments (tail -r isn't available everywhere)
  local selected
  selected=$(fc -lnr 1 | fzf)
  [ -n "$selected" ] && fc -e - -n "$selected"
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
