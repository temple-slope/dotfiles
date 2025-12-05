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