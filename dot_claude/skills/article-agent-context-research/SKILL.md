---
name: article-agent-context-research
description: 記事執筆の前工程として、周辺情報をWeb等で検索し、一次情報・論点・反論・用語・数字を揃えたContext Packを作る。
---

# Article Agent Context Research (周辺リサーチ)

## 前提条件

| 項目           | 詳細                                                                    |
| -------------- | ----------------------------------------------------------------------- |
| スクリプトパス | `dot_claude/scripts/grok_context_research.ts`                           |
| 実行コマンド   | `npx tsx dot_claude/scripts/grok_context_research.ts --topic "..."`     |
| 必要な環境変数 | `XAI_API_KEY`（Grok API キー）                                          |
| 依存スキル     | 別リポジトリ `x-research-skills` に拡張スキルが存在するが、単独使用も可 |

環境変数が未設定の場合は Step 5 の Grok 委任をスキップし、Web 検索のみで Context Pack を作成する。

## Overview

`factcheck` は「書いた後の裏取り」。これは「書く前の地ならし」。任意のネタ/問いについて、Web上の一次情報/定義/反論/関連事例を集め、記事が"薄くならない"状態を作る。

## Defaults (this project)

- プラットフォーム: X(Twitter) 固定（記事はX配信前提）
- 目的: impressions の最大化
- 想定読者: 投資家、エンジニア向けユーザー
- アカウント: 個人発信（投資家・経営者インフルエンサー）
- 領域: AI / Web3
- トンマナ: 常体、ストーリー薄め、結論先出し
- NG: 追加のNG指定なし（ただし投資助言/断定は避ける）

## When To Use

- `$article-agent-ideation` の候補が良いが、記事にすると"中身が薄い"懸念がある
- 定義/一次情報/反論が揃っていない
- Webの周辺情報（公式ドキュメント、GitHub、論文、仕様、比較）を拾って深みを出したい
- `$article-agent-outliner` の前に、材料を厚くしたい

## Intake (ask first if missing)

- 何を調べるか（そのまま日本語でOK。例: 「ClaudeにX検索スキルを足してリサーチを自動化する」）
- どちらに寄せるか: 投資家 / エンジニア
- 記事の狙い（1文。仮でOK）

不足なら最初にこれだけ質問する:

- 「何を周辺リサーチする？（そのまま入力して）」

## Inputs (preferred)

- Idea Creation Report: `data/idea-creation/*_ideation.md`（最新）
- （任意）Xリンク深掘り: `data/article-research/*`（あれば）

## Workflow

1. Select topic
   入力された「調べたいこと」を、そのまま検索/整理の主題にする。
   （Idea Creation Report起点なら、候補の該当セクションをそのまま貼っても良い。）

2. Web search plan
   以下の"型"で検索クエリを作り、幅を出す（最低8クエリ）。

- 定義: `X API 検索 エンドポイント` / `Claude Code skills` など
- 一次情報: 公式Docs / 公式ブログ / 仕様 / 料金 / 利用規約
- 実装: GitHub / sample code / SDK / MCP server examples
- 反論: 制限、レート、偏り、信頼性、コンプラ
- 比較: 代替手段（RSS/Reddit/News/公式更新）との違い

3. Collect sources (priority)
   優先順位:

- 公式（一次情報） > GitHub（実装） > 信頼できる二次情報

4. Extract "depth"
   記事が深くなる要素を最低2つ作る:

- 数字（dated）: 料金/レート/制限/仕様
- 反論と返し: 「できないこと/危険」と「対策」
- 定義: 用語の誤解を潰す一文

5. Draft context pack (Grok delegate)

   `XAI_API_KEY` が設定されている場合、以下のコマンドで Grok（x_search）に周辺情報リサーチを委任する:

   ```bash
   # 基本実行
   npx tsx dot_claude/scripts/grok_context_research.ts --topic "調べたいトピック"

   # オプション一覧
   # --topic     調査トピック（必須）
   # --dry-run   API 呼び出しをスキップして動作確認のみ
   # --output    出力ファイルパス（デフォルト: ~/Documents/Development/claude-output/research/）
   ```

   **失敗時のデバッグ手順**:
   1. `--dry-run` オプションで API 呼び出しなしの動作確認
   2. `echo $XAI_API_KEY` で環境変数が設定されているか確認
   3. スクリプトが存在するか `ls dot_claude/scripts/grok_context_research.ts` で確認
   4. API キー未設定・スクリプト未発見の場合は、この Step をスキップして Web 検索結果のみで Context Pack を作成する

   実行後、`references/context_pack_template.md` の形に整形する（引用は短く、URLで追える形）。

## Output (required)

必ず `~/Documents/Development/claude-output/research/` に Context Pack を1つ保存する。

- ファイル名: `YYYYMMDD_HHMMSSZ_context.md`（UTC推奨）
- テンプレ: `references/context_pack_template.md`
- 末尾に Sources（URL）一覧を入れる

備考:

- `npx tsx dot_claude/scripts/grok_context_research.ts` は `.json/.txt/.md` も併せて保存する（調査ログ用）
- `openai.yaml` は OpenAI API を使うエージェントフレームワーク向けの設定ファイル。CLI から直接このスキルを呼び出す場合は不要

## Hand-off

- 見出し作成: `$article-agent-outliner`（Context Packを入力にする）
- 本文執筆: `$article-agent-writer`
- 書き上げ後の裏取り: `$article-agent-research-factcheck`
