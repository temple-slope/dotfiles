---
name: x-signal-backfill
description: 過去のXポストを一括取得し、3観点分析を実行して signals_history.jsonl を生成する。バックテスト用シグナル履歴の事前準備に使用。「バックフィル」「バックテスト用データ準備」「過去シグナル生成」と言われたら使用する。
---

# X Signal Backfill (バックテスト用シグナル履歴生成)

## 前提条件

| 項目 | 詳細 |
|------|------|
| 依存スキル | x-signal-macro, x-signal-sentiment, x-signal-flow |
| Xデータ取得 | `dot_claude/scripts/grok_account_timeline.ts` |
| 必要な環境変数 | `XAI_API_KEY` |
| 出力先 | `user_data/strategies/x-signal/signals_history.jsonl` |
| チューニング | `user_data/strategies/x-signal/tuning.json` |

## Intake

1. **期間** - 何日分遡るか（デフォルト: 90日）
2. **取得件数** - 何件取得するか（デフォルト: 100件）

引数で指定: `/x-signal-backfill --days 90`

## Workflow

### Step 1: tuning.json 読み込み

`~/Documents/Development/freqtrade/user_data/strategies/x-signal/tuning.json` からアカウント・アセットを取得。

### Step 2: 過去ポスト一括取得

```bash
cd ~/Documents/Development/chezmoi && npx tsx dot_claude/scripts/grok_account_timeline.ts \
--account "@zerohedge" --count 100 --days 90
```

長期間（90日超）の場合は複数回に分割:
- 1回目: --days 90 --count 100
- 2回目: --days 180 --count 100（90日以前のデータ）

### Step 3: ポストを時系列ソート

取得したポストを日時順（古い → 新しい）にソート。

### Step 4: バッチ分析

ポストを時系列グループに分割（例: 1日ごと、または15分足に合わせた区間）。

各グループに対して3分析SKILLを実行:
- x-signal-macro
- x-signal-sentiment
- x-signal-flow

**注意**: 大量のポストを一度に分析するとコンテキストが溢れるため、10-20件ずつバッチ処理する。

### Step 5: signals_history.jsonl 生成

各バッチの結果を signals_history.jsonl に追記:
```jsonl
{"timestamp":"2026-01-15T08:00:00Z","pair":"BTC/USDC:USDC","macro_score":0.3,"sentiment_score":-0.2,"flow_score":0.1,"combined_score":0.07,"direction":"neutral"}
{"timestamp":"2026-01-15T12:00:00Z","pair":"BTC/USDC:USDC","macro_score":0.7,"sentiment_score":0.5,"flow_score":0.4,"combined_score":0.53,"direction":"long"}
```

タイムスタンプはポストの投稿時刻に合わせる。同じ時間帯に複数ポストがある場合は最新のスコアを使用。

### Step 6: ローソク足データダウンロード

バックテストに必要なローソク足データをダウンロード:
```bash
cd ~/Documents/Development/freqtrade && \
docker compose run --rm x-signal download-data \
--config /freqtrade/user_data/strategies/x-signal/config.json \
--timerange 20251228-20260328 -t 15m
```

timerange はシグナル履歴の最古〜最新+バッファに合わせる。

### Step 7: バックテスト実行（オプション）

データ準備が完了したらバックテスト:
```bash
cd ~/Documents/Development/freqtrade && \
docker compose run --rm x-signal backtesting \
--config /freqtrade/user_data/strategies/x-signal/config.json \
--strategy XSignalStrategy \
--timerange 20260101-20260328
```

### Step 8: 結果レポート

- 生成したシグナル数
- 期間カバレッジ
- シグナル分布（long / short / neutral の割合）
- バックテスト結果（実行した場合）

## 注意事項

- Grok API のレート制限に注意。大量リクエストの場合は間隔を空ける
- 既存の signals_history.jsonl がある場合、重複タイムスタンプは上書きしない（新規のみ追記）
- バックフィルデータは過去の情報で生成するため、「後知恵バイアス」に注意。分析SKILLにはポスト時点の情報のみ使う

## Hand-off

- バックテスト結果の改善 → tuning.json の重み・閾値を調整して再バックテスト
- ライブ監視開始 → `/loop 15m /x-signal-trader`
