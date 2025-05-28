#!/bin/bash

# ~/.config/zsh/local.zsh を自動生成する（初回のみ）
cat <<EOF > "{{ .chezmoi.homeDir }}/.config/zsh/local.zsh"
# local zsh settings (not under Git control)
# You can customize this per machine

# example:
# export ZSH_THEME="powerlevel10k/powerlevel10k"
EOF
