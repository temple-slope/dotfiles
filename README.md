# Dotfiles

[chezmoi](https://chezmoi.io/) で管理されている macOS 用の個人 dotfiles リポジトリです。シェル設定、アプリケーション設定、自動セットアップスクリプトを含みます。

## 新しい PC へのセットアップ手順

### 1. Homebrew のインストール

macOS のパッケージマネージャーである Homebrew をインストールします。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. このリポジトリのクローン

dotfiles を管理しているこのリポジトリを、chezmoi のソースディレクトリにクローンします。

```bash
git clone https://github.com/temple-slope/dotfiles.git ~/Documents/Development/chezmoi
```

### 3. 各種ツールのインストール

`Brewfile` を使って、`chezmoi` 自身を含む必要なツールを一括でインストールします。

```bash
brew bundle --file=~/Documents/Development/chezmoi/Brewfile
```

### 4. dotfiles の適用

以下のコマンドで、リポジトリ内の設定をホームディレクトリに反映させます。`run_once_` スクリプトが実行され、必要な設定が自動的に行われます。

```bash
chezmoi apply
```

## 機密情報の設定

この設定では、機密情報を `.env.*` ファイルで管理します。これらのファイルは git/chezmoi 管理外です。

### 1. `.env.chezmoi` の作成

Git 認証情報を設定します。`.env.chezmoi.example` をコピーして値を記入してください。

```bash
cp .env.chezmoi.example .env.chezmoi
```

```env
GIT_USER_NAME=your-git-name
GIT_USER_EMAIL=your-email@example.com
GIT_SIGNING_KEY=ssh-ed25519 AAAA...
```

`chezmoi apply` 時にこのファイルが読み込まれ、`.gitconfig` に反映されます。

### 2. `.env.zsh` の作成

シェルで使用する API キー等のシークレットを設定します。`.env.zsh.example` をコピーして値を記入してください。

```bash
cp .env.zsh.example .env.zsh
```

シェル起動時に `env.zsh` から自動的に読み込まれます。

### 3. 1Password SSH エージェント（任意）

SSH 認証とコミット署名に 1Password SSH エージェントを使用する場合:

1. 1Password デスクトップアプリの **設定 → 開発者** で **SSH エージェントを使用する** を有効化
2. SSH 公開鍵を GitHub の [SSH and GPG keys](https://github.com/settings/keys) に **Signing Key** として登録

## アーキテクチャ

### Chezmoi のファイル命名規則

| Prefix/Suffix | 説明                                 | 例                                  |
| ------------- | ------------------------------------ | ----------------------------------- |
| `dot_`        | 出力先で `.` に変換                  | `dot_zshrc` → `.zshrc`              |
| `private_`    | 600 パーミッション                   | `private_dot_ssh/config`            |
| `.tmpl`       | Go テンプレート処理                  | `.chezmoi.yaml.tmpl`                |
| `run_once_`   | `chezmoi apply` 時に一度だけ実行     | `run_once_install-packages.sh.tmpl` |
| `symlink_`    | コピーではなくシンボリックリンク作成 | -                                   |

### 主要ファイル

- `.chezmoi.yaml.tmpl` - chezmoi のメイン設定（`.env.chezmoi` から Git 認証情報を取得）
- `Brewfile` - `brew bundle` で管理される Homebrew パッケージ
- `run_once_*.sh.tmpl` - 初回セットアップスクリプト（パッケージインストール、macOS 設定、tmux セットアップ等）

### Zsh 構成

`.zshrc` は最初に sheldon プラグインを読み込み、その後 `~/.config/zsh/` 内の `*.zsh` ファイルを順次読み込みます。

| ファイル        | 役割                                       |
| --------------- | ------------------------------------------ |
| `alias.zsh`     | シェルエイリアス                           |
| `defer.zsh`     | fzf キーバインド遅延読み込み               |
| `env.zsh`       | 環境変数 + `.env.zsh` からシークレット読み込み |
| `functions.zsh` | カスタム関数                               |
| `init.zsh`      | tmux 自動起動、履歴設定、VSCode 統合       |
| `path.zsh`      | PATH 追加（scripts, antigravity）          |
| `theme.zsh`     | Powerlevel10k テーマ設定                   |
| `local.zsh`     | マシン固有の設定（chezmoi 管理外）         |

### プラグイン管理

**sheldon** を Zsh プラグインマネージャーとして使用しています（`~/.config/sheldon/plugins.toml`）。

主なプラグイン:

- zsh-defer
- oh-my-zsh
- zsh-autosuggestions
- autojump
- zsh-syntax-highlighting
- powerlevel10k

## よく使うコマンド

### dotfiles の適用

```bash
chezmoi apply
```

### 他の PC からの変更を取り込む

リモートの変更を pull して適用します。

```bash
chezmoi update
```

### 設定ファイルの編集

```bash
# ~/.zshrc を編集したい場合
chezmoi edit ~/.zshrc

# 編集後は忘れずに適用
chezmoi apply
```

### ホームディレクトリのファイルを直接編集してしまった場合

```bash
# 変更を chezmoi に取り込む
chezmoi add ~/.zshrc
```

### Brewfile の更新

`brew` でパッケージをインストール・アンインストールした後:

```bash
# エイリアスを使う場合（/tmp に一時出力し、diff して手動マージ）
brew-dump

# 直接上書きする場合
brew bundle dump --global --force --describe
```

## CI/CD

GitHub Actions で PR 時に以下の Lint を実行します:

- **ShellCheck** - `.sh` / `.sh.tmpl` ファイルの構文チェック（`--severity=warning`）
- **JSON Validate** - `.json` ファイルの構文検証
- **Lua Check** - `.lua` ファイルの静的解析
- **YAML Lint** - `.yml` / `.yaml` ファイルの構文チェック

ローカルで ShellCheck を実行する場合:

```bash
git ls-files '*.sh' '*.sh.tmpl' | xargs -r shellcheck --severity=warning
```

## 機密情報の取り扱い

- `.env.chezmoi` - Git 認証情報（chezmoi テンプレート用、git/chezmoi 管理外）
- `.env.zsh` - API キー等のシークレット（シェル環境変数用、git/chezmoi 管理外）
- `local.zsh` は `.gitignore` で管理外
