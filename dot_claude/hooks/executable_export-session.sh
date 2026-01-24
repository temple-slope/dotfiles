#!/bin/bash
# Claude Code SessionEnd hook - Export session to JSONL
# Saves sessions to ~/Documents/Development/claude-sessions/

set -euo pipefail

EXPORT_DIR="$HOME/Documents/Development/claude-sessions"
PLANS_EXPORT_DIR="$EXPORT_DIR/plans"

# Create export directories
mkdir -p "$EXPORT_DIR"
mkdir -p "$PLANS_EXPORT_DIR"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract fields from JSON input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty')

# Exit if no transcript path
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
    exit 0
fi

# Extract project name from cwd (last component of path)
PROJECT_NAME=$(basename "$CWD" | tr ' ' '-')

# Get current timestamp for filename
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# Copy session file
cp "$TRANSCRIPT_PATH" "$EXPORT_DIR/${TIMESTAMP}_${PROJECT_NAME}.jsonl"

# Copy plan files
if [[ -d "$HOME/.claude/plans" ]]; then
    for plan_file in "$HOME/.claude/plans"/*.md; do
        if [[ -f "$plan_file" ]]; then
            cp "$plan_file" "$PLANS_EXPORT_DIR/"
        fi
    done
fi

exit 0
