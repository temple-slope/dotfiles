# dotfiles

This repository contains my personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Overview

This repository stores my personal configuration files and dotfiles, managed using chezmoi. These configurations are designed to work across different machines while maintaining consistency in my development environment.

## Prerequisites

- [chezmoi](https://www.chezmoi.io/install/) - Dotfile manager
- Git

## Structure

The repository is organized as follows:

- `dot_config/` - Configuration files for various applications
- `run_once_*` - One-time setup scripts
- `run_*` - Regular maintenance scripts

## Usage

- To apply changes: `chezmoi apply`
- To edit a file: `chezmoi edit <file>`
- To see what would change: `chezmoi diff`
- To update from remote: `chezmoi update`

## License

MIT License
