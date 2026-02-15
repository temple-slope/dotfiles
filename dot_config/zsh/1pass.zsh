#!/bin/zsh

# 1Password Environments でマウントされた .env ファイルを読み込む
# - FIFO（named pipe）経由でシークレットが配信される（ディスクに平文は残らない）
# - 1Password デスクトップアプリが起動している必要がある
# - マウントパスは 1Password アプリの Environments 設定で指定

OP_ENV_FILE="${HOME}/.config/op/.env"

if [[ -e "$OP_ENV_FILE" ]]; then
  # set -a: 読み込んだ変数を自動的に export する
  set -a
  source "$OP_ENV_FILE"
  set +a
fi
