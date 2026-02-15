#!/bin/bash
# Claude Code notification hook - macOS alert with sound

EVENT_TYPE="${1:-unknown}"

case "$EVENT_TYPE" in
  stop)
    TITLE="Claude Code"
    MESSAGE="応答が完了しました"
    ;;
  permission)
    TITLE="Claude Code"
    MESSAGE="権限の確認が必要です"
    ;;
  elicitation)
    TITLE="Claude Code"
    MESSAGE="入力が必要です"
    ;;
  *)
    TITLE="Claude Code"
    MESSAGE="通知があります"
    ;;
esac

osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"default\""
exit 0
