---
name: x-signal-flow
description: Xポストからフロー・ポジション情報（大口動向・取引所入出金・清算情報・OI変化）を分析し、各アセットへの影響スコアを算出する。x-signal-traderのサブスキル。単体で呼ばれることは少ない。
---

# X Signal Flow (フロー/ポジション分析)

## Overview

Xポストのテキストから、資金フロー・ポジション動向に関する情報を分析する。
x-signal-trader から呼ばれるサブスキル。

## Input

サブエージェントの prompt で以下が渡される:
- `posts`: Xポストのテキスト一覧（投稿日時付き）
- `assets`: 対象アセット一覧（例: `["BTC/USDC:USDC"]`）

## 分析基準

### 強気シグナル（+0.5 〜 +1.0）
- 大口の買い集め（"whale accumulation", "large BTC purchases"）
- 取引所からの大量出金（"exchange outflows", "coins moving to cold storage"）
- ショートスクイーズの兆候（"short squeeze", "shorts liquidated"）
- ETF/ファンドへの資金流入（"ETF inflows", "institutional buying"）
- OI増加 + 価格上昇（建玉拡大 = 新規ロング優勢）

### 弱気シグナル（-0.5 〜 -1.0）
- 大口の売り（"whale selling", "large transfers to exchanges"）
- 取引所への大量入金（"exchange inflows" = 売り準備）
- ロング清算（"longs liquidated", "$XXM liquidated"）
- ETF/ファンドからの資金流出（"ETF outflows", "institutional selling"）
- OI増加 + 価格下落（建玉拡大 = 新規ショート優勢）

### 中立（-0.5 〜 +0.5）
- 具体的な数値のないフロー言及
- 方向性が不明確な資金移動
- 小規模な清算

### 数値の解釈ガイド
- BTC: 取引所フロー > 10,000 BTC は有意
- 清算: > $100M は有意なイベント
- ETFフロー: > $500M/日 は有意

## Output

JSON形式で返す:
```json
{
"analysis_type": "flow",
"results": [
{
"pair": "BTC/USDC:USDC",
"score": 0.8,
"reason": "Large exchange outflows reported; whale accumulation signals detected"
}
],
"relevant_posts": ["post_id_1", "post_id_3"],
"summary": "Net bullish flow signals with significant exchange withdrawals"
}
```

## 注意事項

- フロー情報は具体的な数値を伴うポストを重視する
- 「噂」レベルのフロー情報はスコアを低めに
- 清算情報は既に起きた結果なので、今後の方向性への示唆として解釈する
- マイナー間のウォレット移動と取引所フローを区別する
