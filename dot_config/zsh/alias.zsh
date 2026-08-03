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
alias codex-skip='codex --dangerously-bypass-approvals-and-sandbox'
alias claude-skip-discord='claude --dangerously-skip-permissions --channels plugin:discord@claude-plugins-official'
# brew-dump: 現在の環境を chezmoi 管理の Brewfile に直接ダンプ
alias brew-dump='brew bundle dump --file="$(chezmoi source-path)/Brewfile" --force'
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

# gws (Google Workspace CLI) のアカウント切替
# default `gws` は ~/.config/gws/ を使う (= 主アカウント)
# `~/.gws-profiles/<name>/` を作ると `gws-<name>` エイリアスが自動生成される
# プロファイル追加は functions.zsh の `gws-new <name>` を使う
if [[ -d "$HOME/.gws-profiles" ]]; then
  for _gws_profile_dir in "$HOME/.gws-profiles"/*/; do
    [[ -d "$_gws_profile_dir" ]] || continue
    _gws_profile_name="${${_gws_profile_dir%/}:t}"
    alias "gws-${_gws_profile_name}"="GOOGLE_WORKSPACE_CLI_CONFIG_DIR=$HOME/.gws-profiles/${_gws_profile_name} gws"
  done
  unset _gws_profile_dir _gws_profile_name
fi
