#!/bin/zsh

# --- System / Appearance ---
# Dark mode
defaults write -g AppleInterfaceStyle Dark
# Disable press-and-hold for keys (enables key repeat)
defaults write -g ApplePressAndHoldEnabled -bool false
# Disable automatic period substitution
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# --- Mouse & Trackpad ---
# Set mouse tracking speed (range: 0–3.0)
defaults write -g com.apple.mouse.scaling 3.0
# Set trackpad tracking speed
defaults write -g com.apple.trackpad.scaling 24
# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# --- Keyboard ---
# InitialKeyRepeat: 10 = 150ms, KeyRepeat: 1 = 15ms
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1

# --- Finder ---
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true
# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Sort folders before files
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Use list view by default (Nlsv)
defaults write com.apple.finder FXPreferredViewStyle Nlsv
# New window opens to Home folder
defaults write com.apple.finder NewWindowTarget PfHm

# --- Dock ---
# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true
# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
# Set Dock tile size
defaults write com.apple.dock tilesize -int 65
# Don't rearrange Spaces based on recent use
defaults write com.apple.dock mru-spaces -bool false

# --- Screenshots ---
# Save screenshots to ~/Documents/ScreenShot
SCREENSHOT_DIR="${HOME}/Documents/ScreenShot"
mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"

# Restart affected apps to apply changes
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "macOS settings have been configured."
echo "Some changes may require a logout/login or restart."
