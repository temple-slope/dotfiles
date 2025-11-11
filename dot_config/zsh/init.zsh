# tmuxを起動していない場合は起動する
if command -v tmux >/dev/null 2>&1; then
  if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    tmux attach-session -t default || tmux new-session -s default
  fi
fi

# ビープ音を無効にする
setopt NO_BEEP

# vscodeのshell integrationを有効にする
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"


# nvmを有効にする
export NVM_DIR="$HOME/.nvm"
# Homebrewのnvmをロード
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# 補完を有効化（オプション）
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
