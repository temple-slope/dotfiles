---
name: chezmoi
description: chezmoiを使ったdotfiles管理操作。~/配下の設定ファイルを編集・追加・同期する際に使用する。
---

# chezmoi dotfiles 管理

**重要: `~/`配下のファイルを直接編集しない。必ずこのスキルのワークフローに従うこと。**

## 基本コマンド

```bash
# dotfilesをシステムに適用
chezmoi apply

# 管理対象ファイルをソースディレクトリで編集
chezmoi edit ~/.zshrc

# ソースディレクトリのパスを確認
chezmoi source-path ~/.zshrc

# 変更差分の確認（適用前に必ず確認）
chezmoi diff

# 管理ファイルの一覧
chezmoi managed
```

## 操作別ワークフロー

### 既存ファイルを編集する

```bash
# 1. chezmoi 経由で編集（ソースディレクトリが開く）
chezmoi edit ~/.zshrc

# 2. 変更を確認
chezmoi diff

# 3. システムに適用
chezmoi apply
```

### 新しいファイルを chezmoi 管理に追加する

```bash
# 1. ファイルを追加
chezmoi add ~/.config/newapp/config.yaml

# 2. 必要に応じてソースファイルを編集
chezmoi edit ~/.config/newapp/config.yaml
```

### 管理対象ファイルが直接変更された場合（cz-sync）

Claude Code 設定変更・エイリアス追加など、管理ファイルが直接更新された場合:

```bash
# 全管理ファイルの変更をソースに同期（chezmoi re-add のエイリアス）
cz-sync
```

## 命名規則（ソースディレクトリ内）

| プレフィックス/サフィックス | 意味 |
|---|---|
| `dot_` | 先頭の `.` に変換（例: `dot_zshrc` → `.zshrc`）|
| `private_` | パーミッション 600 |
| `.tmpl` | Go テンプレートとして処理 |
| `run_once_` | `chezmoi apply` 時に一度だけ実行 |
| `symlink_` | コピーではなくシンボリックリンクを作成 |
| `executable_` | 実行権限を付与 |

## Claude Code 設定ファイル（dot_claude/）

chezmoi で管理している Claude Code 関連ファイル:

```
dot_claude/
├── CLAUDE.md          # グローバル指示
├── settings.json      # 設定（モデル・権限・フック）
├── commands/          # カスタムコマンド
├── hooks/             # セッションフック
├── rules/             # ルールファイル
└── skills/            # カスタムスキル
```

これらを変更する場合:
1. `~/Documents/Development/chezmoi/dot_claude/` 配下を直接編集（chezmoi ソースディレクトリ）
2. `chezmoi apply` でシステムに反映
3. または `~/.claude/` 配下が変更された場合は `cz-sync` で同期

## 注意事項

- `~/.claude/`・`~/.zshrc` 等を**直接編集しない**
- 編集は必ず chezmoi ソースディレクトリ（`~/Documents/Development/chezmoi/`）で行う
- `.tmpl` ファイルは Go テンプレート構文に従う
- `chezmoi apply` 前に必ず `chezmoi diff` で変更を確認する

## エラーリカバリー

### 詳細ログで原因を確認する

```bash
chezmoi apply --verbose
```

### よくあるエラーと対処法

| エラー | 原因 | 対処法 |
|---|---|---|
| `target modified` | ターゲットファイルがソースより新しい | `cz-sync` でソースに取り込む。または `chezmoi diff` で差分を確認し、どちらを正とするか判断する |
| `template: ... parse error` | `.tmpl` ファイルの Go テンプレート構文エラー | `chezmoi execute-template < source.tmpl` で構文を確認・デバッグする |
| `permission denied` | パーミッション不一致 | `chezmoi apply --verbose` でどのファイルか特定し、`ls -la` で現状を確認する |
| `not managed by chezmoi` | 対象ファイルが chezmoi 管理外 | `chezmoi add <file>` で管理下に追加する |

### `.tmpl` 構文の確認

```bash
# テンプレートを実行してレンダリング結果を確認
chezmoi execute-template < dot_zshrc.tmpl

# 特定の変数を渡して確認
chezmoi execute-template '{{ .chezmoi.os }}'
```

### conflict 状態からの回復

| 状況 | コマンド | 使い分け基準 |
|---|---|---|
| ソース（chezmoi リポジトリ）を正とする | `chezmoi apply --force` | ターゲットの変更を捨てて良い場合 |
| ターゲット（`~/` 配下）の変更を取り込む | `cz-sync` | ターゲットの変更が正しく、ソースに反映したい場合 |
| 差分を確認してから判断する | `chezmoi diff` | どちらが正しいか不明な場合（推奨） |
