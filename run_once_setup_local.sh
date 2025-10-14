#!/bin/bash
# ~/.config/zsh/local.zsh を自動生成する（初回のみ）
set -eu

mkdir -p "$HOME/.config/zsh"

cat <<'LOCAL_ZSH' > "$HOME/.config/zsh/local.zsh"
# ~/.config/zsh/local.zsh
# このファイルには個別の設定を記述してください。
# 例:
# export EDITOR="nvim"
# alias ll='ls -alF'

LOCAL_ZSH
