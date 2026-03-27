#!/bin/bash

# Apple Silicon Mac では Homebrew が /opt/homebrew/bin にインストールされるが、
# tmux の run コンテキストのデフォルト PATH に含まれないため、
# oh-my-tmux の TPM 統合が "Cannot use tpm which assumes a globally installed tmux" エラーになる。
# /usr/local/bin にシンボリックリンクを作成して解決する。

HOMEBREW_TMUX="/opt/homebrew/bin/tmux"
SYMLINK_PATH="/usr/local/bin/tmux"

if [ -x "$HOMEBREW_TMUX" ] && [ ! -e "$SYMLINK_PATH" ]; then
  echo "Creating symlink: $SYMLINK_PATH -> $HOMEBREW_TMUX"
  sudo ln -sf "$HOMEBREW_TMUX" "$SYMLINK_PATH"
fi
