#!/bin/zsh
export EDITOR=nvim
export LANG=ja_JP.UTF-8
export XDG_CONFIG_HOME="$HOME/.config"
export FZF_DEFAULT_OPTS='--layout=reverse --height=40%'
export CHEZMOI_SOURCE_DIR="$HOME/Documents/Development/chezmoi"

# シークレット読み込み (.env.zsh は git/chezmoi 管理外)
_ENV_SECRETS="${CHEZMOI_SOURCE_DIR}/.env.zsh"
if [[ -f "$_ENV_SECRETS" ]]; then
  set -a
  source "$_ENV_SECRETS"
  set +a
fi
unset _ENV_SECRETS
