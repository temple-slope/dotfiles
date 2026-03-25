---
name: x-tweet-fetch
description: 特定のXポストURLからスレッド全体・エンゲージメント・リプライを取得し、構造化レポートを作成する。
---

# X Tweet Fetch (Xポスト取得)

## 前提条件

| 項目           | 詳細                                                              |
| -------------- | ----------------------------------------------------------------- |
| スクリプトパス | `dot_claude/scripts/grok_tweet_fetch.ts`                          |
| 実行コマンド   | `npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "..."`      |
| 必要な環境変数 | `XAI_API_KEY`（Grok API キー）                                    |
| 出力先         | `~/Documents/Development/claude-output/x-tweet-fetch/`            |

## Overview

特定のXポストURLを指定して、そのポストの全文・エンゲージメント・スレッド全体・主要リプライをGrok API（x_search）経由で取得し、構造化レポートとして出力する。

## When To Use

- 特定のXポストの詳細情報（本文・エンゲージメント）を取得したい
- スレッド（連投）の全体を時系列で読みたい
- ポストへの主要なリプライを確認したい
- 記事やリサーチの一次ソースとして特定ポストを記録したい

## Intake (ask first if missing)

以下が不足している場合、最初に質問する:

1. **ポストURL** - x.com または twitter.com のポストURL（必須）
2. **リプライ取得**（任意） - 主要リプライも取得するか（デフォルト: スレッドのみ）

## Workflow

### Step 1: 入力確認

- URLが `x.com/*/status/*` または `twitter.com/*/status/*` 形式か確認
- `XAI_API_KEY` が設定されているか確認

### Step 2: スクリプト実行

```bash
# 基本実行（スレッドのみ）
npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123456"

# リプライも取得
npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123456" --replies

# デバッグ（API 呼び出しなし）
npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123456" --dry-run
```

**失敗時のデバッグ手順**:
1. `--dry-run` で API 呼び出しなしの動作確認
2. `echo $XAI_API_KEY` で環境変数が設定されているか確認
3. スクリプトが存在するか確認: `ls dot_claude/scripts/grok_tweet_fetch.ts`
4. URLの形式が正しいか確認（`x.com` or `twitter.com` + `/status/` + 数字ID）
5. API キー未設定・スクリプト未発見の場合は、vxtwitter API (`https://api.vxtwitter.com/{user}/status/{id}`) でフォールバック

### Step 3: 結果整形

スクリプトの出力（stdout）を確認し、以下を検証する:

- ポスト本文が全文取得されているか
- エンゲージメント数値が含まれているか
- スレッドがある場合、全ポストが時系列順に並んでいるか
- メディア情報が記載されているか

### Step 4: 保存確認

スクリプトが以下の3ファイルを自動保存する:

- `{timestamp}_{handle}_{tweetId}.json` - リクエスト/レスポンス全体（デバッグ用）
- `{timestamp}_{handle}_{tweetId}.txt` - 抽出テキスト
- `{timestamp}_{handle}_{tweetId}.md` - Markdown レポート

### Step 5: ユーザーへ報告

以下をハイレベルにまとめて報告する:

- 投稿者・投稿日時
- ポスト本文（全文）
- エンゲージメント数値
- スレッドの有無と件数
- メディアの有無
- 保存先ファイルパス

## Output (required)

`~/Documents/Development/claude-output/x-tweet-fetch/` に保存する。

- ファイル名: `YYYYMMDD_HHMMSSZ_{handle}_{tweetId}.md`
- handle: ハンドル名から `@` を除去し小文字化

## Constraints

- X上の情報はリアルタイム性が高い。取得時点の日時を必ず記録する
- エンゲージメント数は概算で構わない（取得不可の場合は N/A）
- ポスト本文は原文を尊重し、意味を変える要約はしない
- 個人の特定につながる非公開情報は含めない
- 投資助言・断定的表現はレポートに含めない

## Hand-off

- 投稿者の他のポストも見たい場合 → `$x-account-watch`
- トピックを深掘りしたい場合 → `$x-research`
- 記事執筆の材料にする場合 → `$article-agent-context-research`
- そのまま情報として使用する場合 → レポートをユーザーに提示して完了
