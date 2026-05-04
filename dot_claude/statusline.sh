#!/usr/bin/env bash
# Claude Code status line script
# Multi-line format with emojis and progress bar

input=$(cat)

# --- Parse all JSON fields in a single jq call ---
read -r cwd used_pct model < <(echo "$input" | jq -r '[
  (.cwd // ""),
  (.context_window.used_percentage // ""),
  (.model.display_name // "")
] | @tsv')

# --- Current directory (shortened) ---
if [ -n "$cwd" ]; then
  short_cwd="${cwd/#$HOME/\~}"
else
  short_cwd="$(pwd | sed "s|$HOME|~|")"
fi

# --- Git info ---
git_line=""
if [ -n "$cwd" ] && git --no-optional-locks -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  read -r toplevel branch < <(git --no-optional-locks -C "$cwd" rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null | tr '\n' '\t')
  repo_name=$(basename "$toplevel")

  added=0; modified=0; deleted=0
  while IFS= read -r line; do
    idx="${line:0:1}"; wt="${line:1:1}"
    case "$idx" in A) ((added++));; M|R|C) ((modified++));; D) ((deleted++));; esac
    case "$wt" in A) ((added++));; M) ((modified++));; D) ((deleted++));; esac
  done < <(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)

  changes=""
  [ "$added" -gt 0 ]    && changes="${changes} +${added}"
  [ "$modified" -gt 0 ] && changes="${changes} ~${modified}"
  [ "$deleted" -gt 0 ]  && changes="${changes} -${deleted}"

  git_line="🐙 ${repo_name} | 🌿 ${branch}${changes}"
fi

# --- Context usage with progress bar ---
context_model_line=""

if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  # Build progress bar (20 chars wide) without spawning subshells
  bar_width=20
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))
  printf -v filled_bar '%*s' "$filled" ''
  filled_bar=${filled_bar// /█}
  printf -v empty_bar '%*s' "$empty" ''
  empty_bar=${empty_bar// /░}
  context_part="🐹 ${filled_bar}${empty_bar} ${used_int}%"
else
  context_part=""
fi

if [ -n "$model" ]; then
  model_part="💪 ${model}"
else
  model_part=""
fi

if [ -n "$context_part" ] && [ -n "$model_part" ]; then
  context_model_line="${context_part} | ${model_part}"
elif [ -n "$context_part" ]; then
  context_model_line="${context_part}"
elif [ -n "$model_part" ]; then
  context_model_line="${model_part}"
fi

# --- Output multi-line ---
echo "📂 ${short_cwd}"
[ -n "$git_line" ] && echo "$git_line"
[ -n "$context_model_line" ] && echo "$context_model_line"
