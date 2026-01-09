#!/bin/zsh

# Set mouse tracking speed
# The range is from 0 to 3.0
defaults write -g com.apple.mouse.scaling 3.0

# Set key repeat rate
# InitialKeyRepeat: (15 = 225ms)
# KeyRepeat: (2 = 30ms)
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1

# --- Finder ---
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# --- Dock ---
# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# --- Screenshots ---
# Save screenshots to ~/Documents/ScreenShot
SCREENSHOT_DIR="${HOME}/Documents/ScreenShot"
mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"

echo "macOS settings have been configured."
echo "Some changes may require a logout/login or a restart of the affected applications (Finder, Dock)."
