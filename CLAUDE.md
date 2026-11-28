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
- `run_onchange_` プレフィックス → 内容（レンダリング結果）が変わるたびに実行されるスクリプト
- `modify_` プレフィックス → 既存ターゲットを標準入力で受け取り加工する（`chezmoi:modify-template` で揮発キーを保持）
- `symlink_` プレフィックス → コピーではなくシンボリックリンクを作成

### 主要ファイル

- `.chezmoi.yaml.tmpl` - chezmoi のメイン設定（`.env.chezmoi` から Git 認証情報を取得）
- `Brewfile` - `brew bundle` で管理する Homebrew パッケージ
- `.chezmoidata.toml` - テンプレート共有データ（`ai.*`: Codex の trusted プロジェクト・プラグイン・env）
- `.chezmoiexternal.toml` - 外部リポジトリ取得（gpakosz/.tmux など）
- `run_once_*` / `run_onchange_*` - セットアップスクリプト（`install-packages`: Brewfile の変更時に `brew bundle`、`setup_macos`: macOS 設定、`setup_local`: `local.zsh` 生成、`setup_power`: 電源管理）
- `.google-ime/` - Google日本語入力の設定（`config.toml`）とユーザー辞書（`user_dictionary.tsv`、git 管理外）。`run_onchange_after_google-ime.sh.tmpl` が `google_ime.py` で protobuf DB に反映する
- `dot_config/ai-usage/` - AI のレート制限使用量を herdr のタブバー右端に表示する（`ai_usage.py`。Claude は statusline.py が `record` で push、Codex はセッションログを pull。AI の追加は `ADAPTERS` と `config.json` に 1 つずつ足す）
- `AGENTS.md` - `CLAUDE.md` へのシンボリックリンク（Codex 等向け）

### Zsh 設定構造

`.zshrc` は先頭で herdr 外なら `exec herdr`（SSH 先に herdr が無ければ tmux）し、p10k instant prompt → sheldon プラグイン → `~/.config/zsh/` 内の全 `*.zsh` → `~/.p10k.zsh` の順にロード。`typeset -U path` で PATH の重複を排除している:

- `alias.zsh` - シェルエイリアス
- `defer.zsh` - fzf キーバインド遅延読み込み
- `env.zsh` - 環境変数 + `.env.zsh` からシークレット読み込み
- `functions.zsh` - カスタム関数
- `init.zsh` - 履歴設定、VSCode 統合
- `path.zsh` - PATH 追加（scripts, Homebrew python の unversioned コマンド, antigravity）
- `local.zsh` - マシン固有の設定（chezmoi 管理外。メールアドレス等の個人情報もここに置く。例: `GOOGLE_DRIVE_ACCOUNT`）

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

#### settings.json の modify-template 管理

`~/.claude/settings.json` は `dot_claude/modify_private_settings.json`（`chezmoi:modify-template`）で生成する。Claude Code が実行時に書き込む揮発キーとソース管理キーを分離しているため、通常の静的コピーとは運用が異なる:

- **cz-sync（chezmoi re-add）ではソースに同期されない**（modify_ 管理ファイルは re-add がスキップする）。編集は必ずソース側で行う
- **managed キー**（`permissions` / `hooks` / `env` / `statusLine` / `sandbox` / `language` / `cleanupPeriodDays`）の恒久変更は `.chezmoitemplates/claude-settings.json` を編集して `chezmoi apply`
- **揮発キー**（`enabledPlugins` / `extraKnownMarketplaces` / `agentPushNotifEnabled` / `alwaysThinkingEnabled` / `voiceEnabled` / `voice` / `skipDangerousModePermissionPrompt` / `skipAutoPermissionPrompt` の8キー）は各マシンの実行時値が尊重される。新規マシン向けの初期値は `.chezmoitemplates/claude-settings-defaults.json` を編集
- 実行時に「常に許可」で増えた `permissions.allow` は `chezmoi apply` で消える（mergeOverwrite は配列を置換する）。恒久化するには `.chezmoitemplates/claude-settings.json` に手で追記する

### Codex 設定 (dot_codex/)

- Claude Code と同等の設定を維持する（`AGENTS.md` / `hooks.json` / `modify_private_config.toml`）
- `dot_codex/skills/` は `~/.claude/skills/` 内スキルへの `symlink_*.tmpl` で共有する。Codex にも使わせたいスキルはここにシンボリックリンクを追加

### その他の modify-template 管理ファイル

アプリが実行時に書き換える設定は、Claude の settings.json と同じ方式（managed キーだけ上書き、他は既存値を保持、ターゲットが無ければ defaults を使う）で管理する:

| ターゲット | modify ファイル | managed / defaults |
| --- | --- | --- |
| `~/.codex/config.toml` | `dot_codex/modify_private_config.toml` | `.chezmoitemplates/codex-config{,-defaults}.toml` |
| Claude Desktop `claude_desktop_config.json` | `Library/Application Support/private_Claude/modify_private_claude_desktop_config.json` | `.chezmoitemplates/claude-desktop-config{,-defaults}.json` |
| `~/.config/cursor/cli-config.json` | `dot_config/cursor/modify_cli-config.json` | `.chezmoitemplates/cursor-cli-config{,-defaults}.json` |

- managed から削除したキー（例: `.chezmoidata.toml` の `ai.projects` から外したプロジェクト）はターゲットから自動では消えない。不要ならアプリ側で消す

## CI/CD

GitHub Actions が PR と main への push に対して以下の Lint を実行します:

- **ShellCheck** - `.sh` / `.sh.tmpl` ファイルの構文チェック（`--severity=warning`）
- **JSON Validate** - `.json` ファイルの構文検証
- **Lua Check** - `.lua` ファイルの静的解析
- **YAML Lint** - `.yml` / `.yaml` ファイルの構文チェック
- **chezmoi** - 全 `.tmpl` ファイルのテンプレートレンダリング検証（ダミー `.env.chezmoi` を使用）と、`modify_` ファイルを空ターゲットに対して描画した出力の JSON/TOML 構文検証

## 機密データ

- `.env.chezmoi` - Git 認証情報（chezmoi テンプレート用、git/chezmoi 管理外）
- `.env.zsh` - API キー等のシークレット（シェル環境変数用、git/chezmoi 管理外）
- `local.zsh` は gitignore 対象
