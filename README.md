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

## Bitbanck モジュール

Bitbank の公開 API を利用したシンプルな Zsh モジュールを追加しました。`~/.config/zsh/bitbanck.zsh` が自動的に読み込まれ、以下のユーティリティ関数を利用できます。

- `bitbanck_ticker [通貨ペア]` : 指定した通貨ペア（既定は `btc_jpy`）の終値や高値・安値などを表示します。
- `bitbanck_pairs` : 取扱い中の通貨ペア一覧を取得します。

API アクセスには `curl` と `python3` が必要です。取得した数値をもとに簡単なレポートを表示するため、ターミナルから素早く相場を確認したい場合に役立ちます。
必要に応じて `BITBANCK_USER_AGENT` 環境変数を設定すると、API へのリクエストに利用する User-Agent を上書きできます（既定値は `bitbanck.zsh/1.0`）。

## License

MIT License
