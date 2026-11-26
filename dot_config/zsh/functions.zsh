#!/bin/zsh
tmux-current() {
  tmux new-session -As "$(basename "$PWD")"
}

ffileopen() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repo" >&2
    return 1
  fi
  local file
  file=$(git ls-files | fzf)
  [ -n "$file" ] && code "$file"
}

tmux-cd() {
  # 引数でディレクトリを指定（省略時は現在のディレクトリ）
  local target_dir="${1:-$PWD}"

  # ディレクトリの存在確認と絶対パスへの変換
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist" >&2
    return 1
  fi
  target_dir="$(cd "$target_dir" && pwd)"

  # ディレクトリ名をセッション名にする
  local session_name
  session_name="$(basename "$target_dir")"

  # tmux が起動していない場合
  if [[ -z "$TMUX" ]]; then
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux attach -t "$session_name"
    else
      tmux new-session -s "$session_name" -c "$target_dir"
    fi
    return
  fi

  # tmux の中にいる場合
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$target_dir"
    tmux switch-client -t "$session_name"
  fi
}

# herdr 版 tmux-cd: ディレクトリ名のスペース（workspace）へ移動し、無ければそのディレクトリで作る
# Usage: herdr-cd [dir]（省略時は現在のディレクトリ）
herdr-cd() {
  local target_dir="${1:-$PWD}"
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist" >&2
    return 1
  fi
  target_dir="$(cd "$target_dir" && pwd)"
  local name="${target_dir:t}"

  # herdr の外ではサーバーが動いていれば先にスペースを用意してからアタッチする
  if [[ -z "$HERDR_ENV" ]] && ! herdr status server 2>/dev/null | command grep -q '^status: running'; then
    echo "herdr server is not running; starting herdr" >&2
    herdr
    return
  fi

  local workspace_id
  workspace_id="$(herdr workspace list | jq -r --arg name "$name" \
    'first(.result.workspaces[] | select(.label == $name) | .workspace_id) // empty')" || return 1
  if [[ -n "$workspace_id" ]]; then
    herdr workspace focus "$workspace_id" >/dev/null || return 1
  else
    herdr workspace create --cwd "$target_dir" --label "$name" --focus >/dev/null || return 1
  fi

  [[ -z "$HERDR_ENV" ]] && herdr
  return 0
}

# herdr 版 tmux-current: 現在のディレクトリ名のスペースへ移動（無ければ作る）
herdr-current() {
  herdr-cd "$PWD"
}

# gws の追加アカウント用プロファイルを作成して OAuth ログインを起動する
# Usage: gws-new <profile-name>
# 例: gws-new sub  → 以後 `gws-sub ...` で別アカウントを操作できる
gws-new() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: gws-new <profile-name>" >&2
    return 1
  fi
  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: profile name must match [a-zA-Z0-9_-]+" >&2
    return 1
  fi
  local profile_dir="$HOME/.gws-profiles/$name"
  if [[ -d "$profile_dir" ]]; then
    echo "Error: profile already exists at $profile_dir" >&2
    return 1
  fi
  if [[ ! -f "$HOME/.config/gws/client_secret.json" ]]; then
    echo "Error: ~/.config/gws/client_secret.json not found. Run 'gws auth login' for the primary account first." >&2
    return 1
  fi
  mkdir -p "$profile_dir" || return 1
  cp "$HOME/.config/gws/client_secret.json" "$profile_dir/client_secret.json" || return 1
  chmod 600 "$profile_dir/client_secret.json"
  echo "Profile created: $profile_dir"
  echo "Launching OAuth login for profile '$name'..."
  GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$profile_dir" gws auth login
  echo ""
  echo "Done. Start a new shell (or run: source ~/.config/zsh/alias.zsh) to enable: gws-${name}"
}

# 登録済みの gws プロファイル一覧を表示
gws-list() {
  echo "default: ~/.config/gws/  (alias: gws)"
  if [[ -d "$HOME/.gws-profiles" ]]; then
    for d in "$HOME/.gws-profiles"/*/; do
      [[ -d "$d" ]] || continue
      local name="${${d%/}:t}"
      echo "${name}: ${d%/}  (alias: gws-${name})"
    done
  fi
}
