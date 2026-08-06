---
name: x-account-watch
description: 特定のXアカウントの最新ポスト一覧を取得し、構造化されたタイムラインレポートを作成する。
---

# X Account Watch (Xアカウント監視)

## 前提条件

| 項目           | 詳細                                                              |
| -------------- | ----------------------------------------------------------------- |
| スクリプトパス | `dot_claude/scripts/grok_account_timeline.ts`                     |
| 実行コマンド   | `npx tsx dot_claude/scripts/grok_account_timeline.ts --account "..."` |
| 必要な環境変数 | `XAI_API_KEY`（Grok API キー）                                    |
| 出力先         | `~/Documents/Development/claude-output/x-account-watch/`          |

## Overview

特定のXアカウントの直近ポストを Grok API（x_search）経由で取得し、投稿内容・エンゲージメント・投稿傾向を構造化レポートとして出力する。

## When To Use

- 特定アカウントの最新の発言を一覧で確認したい
- アカウントの投稿傾向・頻度を把握したい
- インフルエンサーや競合の直近の発信内容をウォッチしたい
- 記事執筆の参考に特定人物の最近の見解を収集したい

## Intake (ask first if missing)

以下が不足している場合、最初に質問する:

1. **対象アカウント** - Xのハンドル名（例: `@anthropikirai`）
2. **取得件数**（任意） - 何件取得するか（デフォルト: 20件）
3. **期間**（任意） - 何日前まで遡るか（デフォルト: 7日）

## Workflow

### Step 1: 入力確認

- アカウントハンドルが `@` 付きか確認（なければ補完）
- `XAI_API_KEY` が設定されているか確認

### Step 2: スクリプト実行

```bash
# 基本実行
npx tsx dot_claude/scripts/grok_account_timeline.ts --account "@handle"

# オプション指定
npx tsx dot_claude/scripts/grok_account_timeline.ts --account "@handle" --count 10 --days 14

# デバッグ（API 呼び出しなし）
npx tsx dot_claude/scripts/grok_account_timeline.ts --account "@handle" --dry-run
```

**失敗時のデバッグ手順**:
1. `--dry-run` で API 呼び出しなしの動作確認
2. `echo $XAI_API_KEY` で環境変数が設定されているか確認
3. スクリプトが存在するか確認: `ls dot_claude/scripts/grok_account_timeline.ts`
4. API キー未設定・スクリプト未発見の場合は、WebSearch で `site:x.com from:{account}` を使ってフォールバック

### Step 3: 結果整形

スクリプトの出力（stdout）を確認し、以下を検証する:

- 各ポストに日時・本文・エンゲージメント情報が含まれているか
- RT（リポスト）が除外されているか
- スレッドが適切にまとめられているか
- Summary セクションに投稿傾向が記載されているか

### Step 4: 保存確認

スクリプトが以下の3ファイルを自動保存する:

- `{timestamp}_{account_slug}.json` - リクエスト/レスポンス全体（デバッグ用）
- `{timestamp}_{account_slug}.txt` - 抽出テキスト
- `{timestamp}_{account_slug}.md` - Markdown レポート

### Step 5: ユーザーへ報告

以下をハイレベルにまとめて報告する:

- 取得件数
- 期間中の投稿頻度
- 主なトピック（3-5個）
- 最もエンゲージメントの高いポスト
- 保存先ファイルパス

## Output (required)

`~/Documents/Development/claude-output/x-account-watch/` に保存する。

- ファイル名: `YYYYMMDD_HHMMSSZ_{account_slug}.md`
- account_slug: ハンドル名から `@` を除去し小文字化（例: `anthropikirai`）

## Constraints

- X上の情報はリアルタイム性が高い。取得時点の日時を必ず記録する
- エンゲージメント数は概算で構わない（取得不可の場合は N/A）
- ポスト本文は原文を尊重し、意味を変える要約はしない
- 個人の特定につながる非公開情報は含めない
- 投資助言・断定的表現はレポートに含めない

## Hand-off

- 記事執筆の材料にする場合 → `$article-agent-context-research` → `$article-agent-outliner`
- X上の議論を深掘りする場合 → `$x-research`（トピックベースの調査）
- そのままウォッチ結果として使用する場合 → レポートをユーザーに提示して完了
