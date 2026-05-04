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
alias lg="lazygit"
alias d="docker"
alias dc="docker compose"
alias lzd="lazydocker"
alias cz="chezmoi"
alias cz-sync='chezmoi re-add'
alias claude-skip='claude --dangerously-skip-permissions'
alias claude-skip-discord='claude --dangerously-skip-permissions --channels plugin:discord@claude-plugins-official'
# brew-dump: 現在の環境を /tmp/Brewfile.dump にダンプ（chezmoi 管理の Brewfile とは差分マージ前提）
alias brew-dump='brew bundle dump --file="/tmp/Brewfile.dump" --force --describe && echo "Dumped to /tmp/Brewfile.dump - diff and merge manually"'
# brew-install: chezmoi 管理の Brewfile からパッケージを一括インストール
alias brew-install='brew bundle install --file="$(chezmoi source-path)/Brewfile"'
# brew-sync: Brewfile から install 後に既存パッケージを upgrade
alias brew-sync='brew-install && brew upgrade'


alias ls='lsd'
alias ll='lsd -la'
alias lt='lsd --tree'

alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='htop'

alias cddev='cd ~/Documents/Development'
alias cd-drive='cd ~/Library/CloudStorage/GoogleDrive-kazuma.m.h.y@gmail.com/マイドライブ'
alias cd-tax='cd ~/Library/CloudStorage/GoogleDrive-kazuma.m.h.y@gmail.com/マイドライブ/税金関係'
