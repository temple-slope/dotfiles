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
# brew-dump エイリアスは chezmoi ソースの Brewfile に直接 dump する
brew-dump

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

- `.chezmoi.yaml.tmpl` - chezmoi のメイン設定（`.env.chezmoi` から Git 認証情報を取得）
- `Brewfile` - `brew bundle` で管理する Homebrew パッケージ
- `run_once_*.sh.tmpl` - 初回セットアップスクリプト（パッケージインストール、macOS 設定、tmux セットアップ）

### Zsh 設定構造

`.zshrc` はまず sheldon プラグインを読み込み、その後 `~/.config/zsh/` 内の全 `*.zsh` ファイルをロード:

- `alias.zsh` - シェルエイリアス
- `defer.zsh` - fzf キーバインド遅延読み込み
- `env.zsh` - 環境変数 + `.env.zsh` からシークレット読み込み
- `functions.zsh` - カスタム関数
- `init.zsh` - tmux 自動起動、履歴設定、VSCode 統合
- `path.zsh` - PATH 追加（scripts, antigravity）
- `theme.zsh` - Powerlevel10k テーマ設定
- `local.zsh` - マシン固有の設定（chezmoi 管理外）

### プラグイン管理

- **sheldon** - Zsh プラグインマネージャー (`dot_config/sheldon/plugins.toml`)
- プラグイン: zsh-defer, oh-my-zsh, zsh-autosuggestions, autojump, zsh-syntax-highlighting, powerlevel10k

## ワークフロールール

- dotfiles を編集したら、必ず `chezmoi apply` を実行してシステムに反映する
- **このリポジトリ固有のスキルを `dot_claude/skills/` に追加しないこと**: ここで管理するスキルは全プロジェクト横断で使うグローバルスキルのみ。chezmoi 専用の操作（chezmoi apply 自動化など）は CLAUDE.md やプロジェクト内コマンドで完結させる
- **SKILL の追加先は `dot_claude/skills/` に限定すること**: リポジトリ直下の `./.claude/` には SKILL を作成しない（chezmoi 管理外となり `~/.claude/` に反映されないため）。新規 SKILL は `dot_claude/skills/<skill-name>/SKILL.md` に作成し、`chezmoi apply` で `~/.claude/skills/` に展開する

### Dotfile 同期ワークフロー

管理対象ファイルを直接編集した場合（Claude Code 設定変更、エイリアス追加など）:

```bash
cz-sync   # chezmoi re-add のエイリアス。全管理ファイルの変更をソースに同期
```

新しいファイルを chezmoi 管理下に追加する場合:

```bash
chezmoi add ~/.claude/skills/new-skill/SKILL.md
```

### Claude Code 設定 (dot_claude/)

chezmoi で管理しているファイル:

- `settings.json` - 設定（モデル、権限、フック、プラグイン）
- `hooks/` - セッションフック
- `skills/` - カスタムスキル

## CI/CD

GitHub Actions が PR に対して以下の Lint を実行します:

- **ShellCheck** - `.sh` / `.sh.tmpl` ファイルの構文チェック（`--severity=warning`）
- **JSON Validate** - `.json` ファイルの構文検証
- **Lua Check** - `.lua` ファイルの静的解析
- **YAML Lint** - `.yml` / `.yaml` ファイルの構文チェック

## 機密データ

- `.env.chezmoi` - Git 認証情報（chezmoi テンプレート用、git/chezmoi 管理外）
- `.env.zsh` - API キー等のシークレット（シェル環境変数用、git/chezmoi 管理外）
- `local.zsh` は gitignore 対象
