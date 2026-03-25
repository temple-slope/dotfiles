---
name: x-research
description: X(Twitter)上の議論・トレンド・キーパーソンの発言を調査し、構造化されたリサーチレポートを作成する汎用リサーチスキル。
---

# X Research (X調査スキル)

## 前提条件

| 項目           | 詳細                                                        |
| -------------- | ----------------------------------------------------------- |
| 必要なツール   | WebSearch, WebFetch                                         |
| 必要な環境変数 | `XAI_API_KEY`（任意: Grok API によるX検索強化）             |
| 出力先         | `~/Documents/Development/claude-output/x-research/`         |

## Overview

X(Twitter)上の特定トピックに関する議論・意見・トレンドを体系的に調査し、構造化レポートとして出力する。記事執筆の前工程、市場調査、世論分析、競合調査など幅広い用途に対応する。

## When To Use

- X上の特定トピックの議論状況を把握したい
- キーパーソン・インフルエンサーの発言を収集したい
- トレンドや世論の温度感を知りたい
- 記事執筆前にX上のリアルな声を集めたい
- 競合製品・サービスへの反応を調査したい

## Intake (ask first if missing)

以下が不足している場合、最初に質問する:

1. **調査トピック** - 何について調べるか（キーワード or 文章）
2. **調査目的** - 以下から選択（複数可）:
   - `trend` - トレンド・話題性の把握
   - `opinion` - 意見・賛否の収集
   - `influencer` - キーパーソンの発言収集
   - `reaction` - 特定イベント・発表への反応
   - `competitive` - 競合・代替への言及調査
3. **対象言語** - `ja` / `en` / `both`（デフォルト: `both`）
4. **時間範囲** - `24h` / `7d` / `30d` / `all`（デフォルト: `7d`）

## Workflow

### Step 1: 検索クエリ設計

調査トピックと目的から、以下の観点で最低6クエリを設計する:

| 観点         | クエリ例                                         |
| ------------ | ------------------------------------------------ |
| 直接キーワード | `"Claude Code" site:x.com`                      |
| 賛成意見     | `"Claude Code" (すごい OR 便利 OR 最高)`          |
| 批判・課題   | `"Claude Code" (問題 OR 微妙 OR 不満 OR bug)`    |
| 比較         | `"Claude Code" vs (Cursor OR Copilot)`           |
| 影響力者     | `"Claude Code" from:著名アカウント site:x.com`    |
| 数字・実績   | `"Claude Code" (万 OR k OR users OR ARR)`        |

**検索方法の優先順位**:
1. `XAI_API_KEY` が設定されている場合 → Grok API（x_search モード）を優先
2. 未設定の場合 → WebSearch で `site:x.com` / `site:twitter.com` 検索
3. 個別ポストの詳細取得 → WebFetch で x.com URL を直接取得

### Step 2: 情報収集

各クエリで検索を実行し、以下を収集する:

- **ポストURL** - 元ツイートへのリンク
- **投稿者** - アカウント名とフォロワー規模（わかる範囲）
- **投稿日時** - いつの発言か
- **本文要約** - 要点を1-2文で
- **エンゲージメント** - いいね・RT・引用数（取得可能な場合）
- **スレッド有無** - 長文スレッドの場合はスレッド全体を追跡

**収集時の注意**:
- 各クエリ実行後、進捗を報告する
- 重複ポストは除外する
- bot・スパムと思われる投稿は除外する
- 引用元・参照先がある場合は追跡する

### Step 3: Grok 委任（任意）

`XAI_API_KEY` が設定されている場合、Step 2 の WebSearch 結果を補完するために Grok API を活用する:

```bash
npx tsx dot_claude/scripts/grok_context_research.ts --topic "X上の[トピック]に関する議論"
```

Grok の出力は Step 2 の結果とマージし、重複を除去する。

### Step 4: 分析・構造化

収集した情報を以下の軸で整理する:

1. **論調分布** - ポジティブ / ネガティブ / 中立のおおよその比率
2. **主要論点** - 繰り返し言及されるポイント（最大5つ）
3. **キーパーソン発言** - 影響力のあるアカウントの代表的発言
4. **コンセンサス** - 多くが同意している点
5. **論争点** - 意見が割れている点
6. **見落としがちな視点** - 少数だが重要な指摘

### Step 5: レポート出力

以下のテンプレートに従い、レポートを作成する。

## Output (required)

`~/Documents/Development/claude-output/x-research/` に保存する。

- ファイル名: `YYYYMMDD_HHMMSSZ_{topic_slug}.md`
- topic_slug: トピックを英語でケバブケースに変換（例: `claude-code-reactions`）

### レポートテンプレート

```markdown
# X Research Report

## Meta
- Topic: {調査トピック}
- Purpose: {調査目的}
- Language: {対象言語}
- Time range: {時間範囲}
- Generated: {UTC タイムスタンプ}
- Queries executed: {実行クエリ数}
- Posts analyzed: {分析ポスト数}

## Executive Summary
{3-5文で調査結果の要約}

## Sentiment Overview
- Positive: {概算%}
- Negative: {概算%}
- Neutral: {概算%}

## Key Findings
### 1. {論点1}
- Summary:
- Representative posts:
  - [@user](url) - "引用" ({いいね数} likes)

### 2. {論点2}
...

## Influential Voices
| Account | Followers | Stance | Key Quote |
|---------|-----------|--------|-----------|
| @user   | ~10K      | Positive | "..." |

## Consensus Points
- {多くが同意している点}

## Contested Points
- Claim: {主張A}
  - For: {賛成根拠}
  - Against: {反対根拠}

## Minority but Notable Takes
- {少数意見だが重要な指摘}

## Raw Data
<details>
<summary>収集ポスト一覧 ({件数}件)</summary>

| # | Date | Account | Post | URL | Likes | RTs |
|---|------|---------|------|-----|-------|-----|
| 1 | ... | @user | "..." | url | 10 | 3 |

</details>

## Search Queries Used
1. `{query1}` → {結果件数}件
2. `{query2}` → {結果件数}件

## Sources
- {URL一覧}
```

## Constraints

- X上の情報はリアルタイム性が高い。調査時点の日時を必ず記録する
- フォロワー数・エンゲージメント数は概算で構わない（"~10K" 等）
- 投資助言・断定的表現はレポートに含めない
- 個人の特定につながる非公開情報は含めない
- ポストの引用は原文を尊重し、意味を変える要約はしない

## Hand-off

- 記事執筆の材料にする場合 → `$article-agent-context-research` → `$article-agent-outliner`
- そのまま調査報告として使用する場合 → レポートをユーザーに提示して完了
