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
git clone https://github.com/temple-slope/dotfiles.git ~/.local/share/chezmoi
```

### 3. 各種ツールのインストール

`Brewfile` を使って、`chezmoi` 自身を含む必要なツールを一括でインストールします。

```bash
brew bundle --file=~/.local/share/chezmoi/Brewfile
```

### 4. dotfiles の適用

以下のコマンドで、リポジトリ内の設定をホームディレクトリに反映させます。`run_once_` スクリプトが実行され、必要な設定が自動的に行われます。

```bash
chezmoi apply
```

## 1Password 連携

この設定では、Git の認証情報のような機密情報を [1Password](https://1password.com/) で管理します。

### 1. 1Password へのサインイン

`Brewfile` で 1Password CLI はインストール済みです。以下のコマンドでアカウントにサインインしてください。

```bash
op signin
```

### 2. 機密情報アイテムの作成

**Personal** ボルトに **git** という名前でアイテムを作成し、以下のフィールドを追加します。

- `name`: あなたの Git での名前
- `email`: あなたの Git でのメールアドレス

以下のコマンドでも作成できます。

```bash
op item create --category "Secure Note" --title "git" --vault "Personal" 'name[text]=YOUR_GIT_NAME' 'email[text]=YOUR_GIT_EMAIL'
```

### 3. 設定の反映

再度 `chezmoi apply` を実行すると、`.gitconfig` に 1Password から取得した認証情報が反映されます。

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

- `.chezmoi.yaml.tmpl` - chezmoi のメイン設定（1Password 連携含む）
- `Brewfile` - `brew bundle` で管理される Homebrew パッケージ
- `run_once_*.sh.tmpl` - 初回セットアップスクリプト（パッケージインストール、macOS 設定、tmux セットアップ等）

### Zsh 構成

`.zshrc` は最初に sheldon プラグインを読み込み、その後 `~/.config/zsh/` 内の `*.zsh` ファイルを順次読み込みます。

| ファイル        | 役割                               |
| --------------- | ---------------------------------- |
| `env.zsh`       | 環境変数                           |
| `alias.zsh`     | シェルエイリアス                   |
| `functions.zsh` | カスタム関数                       |
| `theme.zsh`     | Powerlevel10k テーマ設定           |
| `local.zsh`     | マシン固有の設定（chezmoi 管理外） |

### プラグイン管理

**sheldon** を Zsh プラグインマネージャーとして使用しています（`~/.config/sheldon/plugins.toml`）。

主なプラグイン:

- oh-my-zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- autojump
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
chezmoi add /.zshrc
```

### Brewfile の更新

`brew` でパッケージをインストール・アンインストールした後:

```bash
brew bundle dump --global --force --describe
```

## CI/CD

GitHub Actions で PR 時に ShellCheck を実行し、`.sh` および `.sh.tmpl` ファイルの構文チェックを行います。

ローカルで実行する場合:

```bash
git ls-files '*.sh' '*.sh.tmpl' | xargs -r shellcheck --severity=warning
```

## 機密情報の取り扱い

- Git 認証情報は 1Password から取得（vault: "Personal", item: "git"）
- `secrets/` ディレクトリと `local.zsh` は `.gitignore` で管理外
