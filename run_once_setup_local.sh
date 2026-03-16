#!/bin/bash

# ~/.config/zsh/local.zsh が存在しない場合のみ自動生成する
LOCAL_ZSH_PATH="$HOME/.config/zsh/local.zsh"

if [ ! -f "$LOCAL_ZSH_PATH" ]; then
  echo "🔧 $LOCAL_ZSH_PATH を生成します..."
  cat <<'EOF' > "$LOCAL_ZSH_PATH"
# -*- mode: zsh; -*-
#
# .config/zsh/local.zsh
#
# このファイルはローカル環境固有の設定を記述するためのものです。
# chezmoiやGitの管理対象外なので、トークンなど機密情報を記述できます。
#
# 例:
# export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

EOF
  echo "✅ 生成しました。"
else
  echo "ℹ️ $LOCAL_ZSH_PATH は既に存在するため、スキップしました。"
fi

# ~/.ssh/config.local が存在しない場合のみ自動生成する
SSH_CONFIG_LOCAL="$HOME/.ssh/config.local"

if [ ! -f "$SSH_CONFIG_LOCAL" ]; then
  echo "🔧 $SSH_CONFIG_LOCAL を生成します..."
  cat <<'EOF' > "$SSH_CONFIG_LOCAL"
# ~/.ssh/config.local
#
# このファイルはマシン固有の SSH 設定を記述するためのものです。
# ~/.ssh/config から Include されます。
# chezmoi や Git の管理対象外なので、プライベートなホスト設定を記述できます。
#
# 例:
# Host my-server
#   HostName 192.168.1.100
#   User admin
#   Port 2222

EOF
  chmod 600 "$SSH_CONFIG_LOCAL"
  echo "✅ 生成しました。"
else
  echo "ℹ️ $SSH_CONFIG_LOCAL は既に存在するため、スキップしました。"
fi
