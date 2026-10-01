#!/bin/bash

set -euo pipefail

# --- Power Management ---
# Never sleep the display, system, or disks (all power sources)
sudo pmset -a displaysleep 0 sleep 0 disksleep 0

# --- Screen Saver ---
# Never start the screen saver
defaults -currentHost write com.apple.screensaver idleTime -int 0

echo "Power settings have been configured."
