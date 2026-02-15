#!/bin/zsh
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias c="clear"
alias h="history"
alias mv="mv -i"
alias cp="cp -i"

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias t="tmux"

alias g="git"
alias d="docker"
alias dc="docker compose"
alias cz="chezmoi"
alias cz-sync='chezmoi re-add'
alias brew-dump='brew bundle dump --file="$(chezmoi source-path)/Brewfile" --force --describe'
alias brew-install='brew bundle install --file="$(chezmoi source-path)/Brewfile"'
alias brew-cleanup='brew bundle cleanup --file="$(chezmoi source-path)/Brewfile" --force'


alias ls='lsd'
alias ll='lsd -la'
alias lt='lsd --tree'

alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='htop'

alias cddev='cd ~/Documents/Development'
