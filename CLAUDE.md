# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## リポジトリ概要

macOS 用の個人 dotfiles リポジトリで、[chezmoi](https://chezmoi.io/) で管理しています。シェル設定、アプリケーション設定、自動セットアップスクリプトを含みます。

## よく使うコマンド

```bash
# dotfiles をシステムに適用
chezmoi apply

# 管理対象ファイルを編集（chezmoi ソースディレクトリで開く）
chezmoi edit ~/.zshrc

# 変更したファイルを chezmoi 管理に追加
chezmoi add ~/.zshrc

# パッケージのインストール/アンインストール後に Brewfile を更新
brew bundle dump --global --force --describe

# シェルスクリプトに対して shellcheck をローカルで実行
git ls-files '*.sh' '*.sh.tmpl' | xargs -r shellcheck --severity=warning
```

## アーキテクチャ

### Chezmoi の命名規則

- `dot_` プレフィックス → 出力先で `.` に変換（例: `dot_zshrc` → `.zshrc`）
- `private_` プレフィックス → 600 パーミッション
- `.tmpl` サフィックス → Go テンプレート処理
- `run_once_` プレフィックス → `chezmoi apply` 時に一度だけ実行されるスクリプト
- `symlink_` プレフィックス → コピーではなくシンボリックリンクを作成

### 主要ファイル

- `.chezmoi.yaml.tmpl` - chezmoi のメイン設定（`promptStringOnce` で Git 認証情報を対話式に取得）
- `Brewfile` - `brew bundle` で管理する Homebrew パッケージ
- `run_once_*.sh.tmpl` - 初回セットアップスクリプト（パッケージインストール、macOS 設定、tmux セットアップ）

### Zsh 設定構造

`.zshrc` はまず sheldon プラグインを読み込み、その後 `~/.config/zsh/` 内の全 `*.zsh` ファイルをロード:

- `env.zsh` - 環境変数
- `alias.zsh` - シェルエイリアス
- `functions.zsh` - カスタム関数
- `theme.zsh` - Powerlevel10k テーマ設定
- `local.zsh` - マシン固有の設定（chezmoi で無視）

### プラグイン管理

- **sheldon** - Zsh プラグインマネージャー (`dot_config/sheldon/plugins.toml`)
- プラグイン: oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, autojump, powerlevel10k

## ワークフロールール

- dotfiles を編集したら、必ず `chezmoi apply` を実行してシステムに反映する

### Dotfile 同期ワークフロー

管理対象ファイルを直接編集した場合（Claude Code 設定変更、エイリアス追加など）:

```bash
cz-sync   # chezmoi re-add のエイリアス。全管理ファイルの変更をソースに同期
```

新しいファイルを chezmoi 管理下に追加する場合:

```bash
chezmoi add ~/.claude/commands/new-command.md
chezmoi add ~/.claude/skills/new-skill/SKILL.md
```

### Claude Code 設定 (dot_claude/)

chezmoi で管理しているファイル:

- `settings.json` - 設定（モデル、権限、フック、プラグイン）
- `commands/` - カスタムコマンド
- `hooks/` - セッションフック
- `skills/` - カスタムスキル

## CI/CD

GitHub Actions が PR に対して全 `.sh` および `.sh.tmpl` ファイルに ShellCheck を `--severity=warning` で実行します。

## 機密データ

- Git 認証情報は `chezmoi init` 時に対話式入力で設定（`~/.config/chezmoi/chezmoi.yaml` に保存）
- `local.zsh` は gitignore 対象
