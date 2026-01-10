# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed by [chezmoi](https://chezmoi.io/) for macOS. It contains shell configurations, application settings, and automated setup scripts.

## Common Commands

```bash
# Apply dotfiles to the system
chezmoi apply

# Edit a managed file (opens in chezmoi source directory)
chezmoi edit ~/.zshrc

# Add a modified file back to chezmoi management
chezmoi add ~/.zshrc

# Update Brewfile after installing/uninstalling packages
brew bundle dump --global --force --describe

# Run shellcheck locally on shell scripts
git ls-files '*.sh' '*.sh.tmpl' | xargs -r shellcheck --severity=warning
```

## Architecture

### Chezmoi Naming Conventions

- `dot_` prefix → `.` in destination (e.g., `dot_zshrc` → `.zshrc`)
- `private_` prefix → 600 permissions
- `.tmpl` suffix → Go template processing
- `run_once_` prefix → Scripts that run once during `chezmoi apply`
- `symlink_` prefix → Creates symlinks instead of copying

### Key Files

- `.chezmoi.yaml.tmpl` - Main chezmoi configuration with 1Password integration for Git credentials
- `Brewfile` - Homebrew packages managed by `brew bundle`
- `run_once_*.sh.tmpl` - One-time setup scripts (package installation, macOS settings, tmux setup)

### Zsh Configuration Structure

The `.zshrc` sources sheldon plugins first, then loads all `*.zsh` files from `~/.config/zsh/`:

- `env.zsh` - Environment variables
- `alias.zsh` - Shell aliases
- `functions.zsh` - Custom functions
- `theme.zsh` - Powerlevel10k theme settings
- `local.zsh` - Machine-specific settings (ignored by chezmoi)

### Plugin Management

- **sheldon** - Zsh plugin manager (`dot_config/sheldon/plugins.toml`)
- Plugins: oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, autojump, powerlevel10k

## Workflow Rules

- After editing dotfiles, always run `chezmoi apply` to apply changes to the system

## CI/CD

GitHub Actions runs ShellCheck on PRs for all `.sh` and `.sh.tmpl` files with `--severity=warning`.

## Sensitive Data

- Git credentials are fetched from 1Password (vault: "Personal", item: "git")
- `secrets/` directory and `local.zsh` are gitignored
