---
name: agent-browser
description: ブラウザ操作を自動化する。Webテスト、フォーム入力、スクリーンショット取得、データ抽出に使用する。
---

# agent-browser によるブラウザ自動化

## 前提条件

- `agent-browser` CLI がインストールされていること
- 確認コマンド: `which agent-browser`

## クイックスタート

```bash
agent-browser open <url>        # ページに移動
agent-browser snapshot -i       # インタラクティブ要素を ref 付きで取得
agent-browser click @e1         # ref でクリック
agent-browser fill @e2 "text"   # ref で入力
agent-browser close             # ブラウザを閉じる
```

## 基本ワークフロー

1. 移動: `agent-browser open <url>`
2. スナップショット: `agent-browser snapshot -i`（`@e1`、`@e2` 等の ref が返る）
3. ref を使って操作
4. ページ遷移や DOM の大きな変更後は再スナップショット

## コマンドリファレンス

### ナビゲーション

```bash
agent-browser open <url>      # URL に移動
agent-browser back            # 戻る
agent-browser forward         # 進む
agent-browser reload          # リロード
agent-browser close           # ブラウザを閉じる
```

### スナップショット（ページ解析）

```bash
agent-browser snapshot        # アクセシビリティツリー全体
agent-browser snapshot -i     # インタラクティブ要素のみ（推奨）
agent-browser snapshot -c     # コンパクト出力
agent-browser snapshot -d 3   # 深さを3に制限
```

### インタラクション（snapshot で取得した @ref を使用）

```bash
agent-browser click @e1           # クリック
agent-browser dblclick @e1        # ダブルクリック
agent-browser fill @e2 "text"     # クリアしてから入力
agent-browser type @e2 "text"     # クリアせずに入力
agent-browser press Enter         # キー押下
agent-browser press Control+a     # キーコンビネーション
agent-browser hover @e1           # ホバー
agent-browser check @e1           # チェックボックスをオン
agent-browser uncheck @e1         # チェックボックスをオフ
agent-browser select @e1 "value"  # ドロップダウン選択
agent-browser scroll down 500     # ページスクロール
agent-browser scrollintoview @e1  # 要素をビューにスクロール
```

### 情報取得

```bash
agent-browser get text @e1        # 要素のテキストを取得
agent-browser get value @e1       # 入力値を取得
agent-browser get title           # ページタイトルを取得
agent-browser get url             # 現在の URL を取得
```

### スクリーンショット

```bash
agent-browser screenshot          # 標準出力へ出力
agent-browser screenshot path.png # ファイルに保存
agent-browser screenshot --full   # ページ全体
```

### 待機

```bash
agent-browser wait @e1                     # 要素が現れるまで待機
agent-browser wait 2000                    # ミリ秒待機
agent-browser wait --text "Success"        # テキストが現れるまで待機
agent-browser wait --load networkidle      # ネットワークアイドルまで待機
```

### セマンティックロケーター（ref の代替）

```bash
agent-browser find role button click --name "Submit"
agent-browser find text "ログイン" click
agent-browser find label "メールアドレス" fill "user@test.com"
```

## 使用例: フォーム送信

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# 出力例: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "送信" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # 結果を確認
```

## 使用例: ログイン状態の保存と再利用

```bash
# 初回ログイン
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# 次回以降: 保存した状態を読み込む
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## セッション（並列ブラウザ）

```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

## JSON 出力（スクリプト連携）

`--json` を付けると機械可読な出力が得られる:

```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```

## デバッグ

```bash
agent-browser open example.com --headed  # ブラウザウィンドウを表示
agent-browser console                    # コンソールメッセージを確認
agent-browser errors                     # ページエラーを確認
```
