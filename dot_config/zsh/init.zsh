#!/bin/zsh
# tmuxを起動していない場合は起動する
if command -v tmux >/dev/null 2>&1; then
  if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    tmux attach-session -t default || tmux new-session -s default
  fi
fi

# ビープ音を無効にする
setopt NO_BEEP

# 履歴設定
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY        # 複数ターミナルで履歴共有
setopt HIST_IGNORE_DUPS     # 直前と同じコマンドを除外
setopt HIST_IGNORE_ALL_DUPS # 重複を全て除外
setopt HIST_FIND_NO_DUPS    # 検索時に重複スキップ
setopt HIST_REDUCE_BLANKS   # 余分な空白を削除

# vscodeのshell integrationを有効にする
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"
