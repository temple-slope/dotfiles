#!/usr/bin/env bash
# gws を複数 Google アカウントで切り替えて実行するラッパー。
# main はデフォルトの gws 設定ディレクトリ(keychain)、それ以外は
# $HOME/.config/gws-profiles/<alias> + file keyring で分離する。
set -euo pipefail

DEFAULT_DIR="$HOME/.config/gws"
PROFILES_DIR="$HOME/.config/gws-profiles"
ACCOUNTS_FILE="${GWS_ACCOUNTS_FILE:-$HOME/.config/gws-profiles/accounts}"

ALIASES=()
EMAILS=()

# accounts ファイルを読み込む。1 行 1 アカウント: <alias> <email>
load_accounts() {
  if [[ ! -f $ACCOUNTS_FILE ]]; then
    accounts_help "accounts file not found: $ACCOUNTS_FILE"
  fi
  local line alias email extra n=0
  while IFS= read -r line || [[ -n $line ]]; do
    n=$((n + 1))
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    read -r alias email extra <<<"$line"
    if [[ ! $alias =~ ^[A-Za-z0-9_-]+$ ]]; then
      echo "error: $ACCOUNTS_FILE line $n: invalid alias '$alias' (allowed: A-Z a-z 0-9 _ -)" >&2
      exit 2
    fi
    if [[ -z $email || -n $extra ]]; then
      echo "error: $ACCOUNTS_FILE line $n: expected '<alias> <email>'" >&2
      exit 2
    fi
    ALIASES+=("$alias")
    EMAILS+=("$email")
  done <"$ACCOUNTS_FILE"
  if [[ ${#ALIASES[@]} -eq 0 ]]; then
    accounts_help "no accounts defined in: $ACCOUNTS_FILE"
  fi
}

accounts_help() {
  cat >&2 <<HELP
error: $1

Create the accounts file (override path with GWS_ACCOUNTS_FILE).
Format: one account per line, "<alias> <email>". Blank lines and lines
starting with '#' are ignored. Alias: [A-Za-z0-9_-]+. "main" uses the
default gws config dir; other aliases use $PROFILES_DIR/<alias>.

Example:
  main  you@example.com
  work  you@work.example.com
HELP
  exit 2
}

usage() {
  cat >&2 <<USAGE
Usage:
  gws-account.sh list
  gws-account.sh <account> <gws args...>
  gws-account.sh all <gws args...>

<account> is an alias or full email:
USAGE
  local i
  for i in "${!ALIASES[@]}"; do
    printf '  %-8s %s\n' "${ALIASES[$i]}" "${EMAILS[$i]}" >&2
  done
  cat >&2 <<'USAGE'

Login example:
  gws-account.sh <alias> auth login -s gmail
USAGE
  exit 2
}

# alias またはメールから index を返す。見つからなければ 1。
resolve() {
  local key=$1 i
  for i in "${!ALIASES[@]}"; do
    if [[ $key == "${ALIASES[$i]}" || $key == "${EMAILS[$i]}" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

config_dir() {
  if [[ ${ALIASES[$1]} == main ]]; then
    echo "$DEFAULT_DIR"
  else
    echo "$PROFILES_DIR/${ALIASES[$1]}"
  fi
}

# 指定 index のアカウント env で gws を実行する(prepare=1 でディレクトリ準備)。
run_gws() {
  local idx=$1 prepare=$2
  shift 2
  if [[ ${ALIASES[$idx]} == main ]]; then
    gws "$@"
    return
  fi
  local dir
  dir=$(config_dir "$idx")
  if [[ $prepare == 1 ]]; then
    if [[ ! -f $DEFAULT_DIR/client_secret.json && ! -f $dir/client_secret.json ]]; then
      echo "error: $DEFAULT_DIR/client_secret.json not found; set up the default gws account first" >&2
      return 1
    fi
    mkdir -p "$dir"
    chmod 700 "$dir"
    if [[ ! -f $dir/client_secret.json ]]; then
      cp "$DEFAULT_DIR/client_secret.json" "$dir/client_secret.json"
      chmod 600 "$dir/client_secret.json"
    fi
  fi
  GOOGLE_WORKSPACE_CLI_CONFIG_DIR=$dir \
    GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file \
    gws "$@"
}

# `gws auth status` は JSON を出力する。credentials が無いと storage が "none" になる。
login_status() {
  local out
  if ! out=$(run_gws "$1" 0 auth status 2>/dev/null); then
    echo error
    return
  fi
  if grep -Eq '"storage"[[:space:]]*:[[:space:]]*"none"' <<<"$out"; then
    echo not-logged-in
  elif grep -Eq '"storage"[[:space:]]*:' <<<"$out"; then
    echo logged-in
  else
    echo error
  fi
}

load_accounts
[[ $# -ge 1 ]] || usage
case $1 in
  -h | --help) usage ;;
  list)
    for i in "${!ALIASES[@]}"; do
      printf '%s\t%s\t%s\t%s\n' "${ALIASES[$i]}" "${EMAILS[$i]}" "$(config_dir "$i")" "$(login_status "$i")"
    done
    ;;
  all)
    shift
    [[ $# -ge 1 ]] || usage
    failed=0
    for i in "${!ALIASES[@]}"; do
      printf '### %s (%s)\n' "${ALIASES[$i]}" "${EMAILS[$i]}"
      run_gws "$i" 1 "$@" || failed=1
    done
    exit "$failed"
    ;;
  *)
    idx=$(resolve "$1") || usage
    shift
    [[ $# -ge 1 ]] || usage
    if [[ ${ALIASES[$idx]} == main ]]; then
      exec gws "$@"
    fi
    run_gws "$idx" 1 "$@"
    ;;
esac
