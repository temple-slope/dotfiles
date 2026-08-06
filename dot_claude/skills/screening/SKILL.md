---
name: screening
description: 決算データからのスクリーニング実行とマークダウンレポート出力。fundamentals サービスの7種スクリーニングAPI（連続増収増益・営業利益率改善・業績予想上方修正・EPS成長率・財務健全性・マルチファクタースコア・セクター内偏差値）を実行し、結果を reports/screening/{日付}_screening_results.md に出力する。「スクリーニング」「銘柄スクリーニング」「決算スクリーニング」「screening」と言われたら使用する。
---

# Screening

決算データベースからスクリーニングを実行し、マークダウンレポートを生成する。

## 前提条件

- `fundamentals` サービスと `redis` が起動していること
- `.env` に `API_SECRET` が設定されていること

```bash
docker compose up -d fundamentals redis
```

## データ品質ルール

- **通期決算（FY）限定**: 全スクリーニングは `type_of_document LIKE 'FY%'` でフィルタ。四半期決算同士の異種期間比較を防止
- **前期黒字限定**: 成長率・修正率は前期が黒字（正の値）の場合のみ算出。赤字→黒転のターンアラウンドは成長率として計算しない
- **前期値の閾値**: 売上・利益: 100万円未満、EPS: 1円未満は NULL 扱い
- **営業利益率改善**: 直近期が黒字（利益率 > 0）の企業のみ。赤字縮小は除外
- **空文字対策**: SQLiteが空文字を0として計算する問題に対応。forecast/実績値の空文字チェック済み
- **forecast_revision**: 最新決算（四半期含む）の通期予想と直近FY実績を比較。FY決算自体にはforecastが入らないため

## ワークフロー

### 1. データ取得

`scripts/run_screening.sh` を実行して全スクリーニング結果のJSONを取得する。

```bash
bash ~/.claude/skills/screening/scripts/run_screening.sh > /tmp/screening_raw.json
```

スクリプトは以下の7エンドポイントを順に呼び出す:
- `/screening/consecutive-growth?min_periods=3&limit=20` - 連続増収増益
- `/screening/margin-improvement?min_margin_change=1.0&limit=20` - 営業利益率改善
- `/screening/forecast-revision?min_revision_pct=10&limit=20` - 業績予想上方修正
- `/screening/eps-growth?min_eps_growth=20&limit=20` - EPS成長率
- `/screening/quality?min_equity_ratio=50&min_roe=10&limit=20` - 財務健全性
- `/screening/multi-factor?limit=20` - マルチファクタースコア
- `/screening/sector-relative?limit=20` - セクター内偏差値

### 2. レポート生成

JSONを読み取り、以下のフォーマットでマークダウンを生成する。

**出力先**: `reports/screening/{YYYY-MM-DD}_screening_results.md`

**ティッカー変換**: J-Quants コードは5桁（末尾0付き）。表示時は末尾の `0` を除去して4桁にする。ただしアルファベット含みコード（例: `153A0` -> `153A`）も同様。

**株探リンク**: 各銘柄に `[株探](https://kabutan.jp/stock/?code={ティッカー})` を付与する。

**テーブルフォーマット例**:

```markdown
## D-1. マルチファクタースコア Top N

| ティッカー | 銘柄 | 市場 | 総合スコア | 売上成長 | 利益成長 | 営業利益率 | ROE | リンク |
|-----------|------|------|----------|---------|---------|----------|-----|-------|
| 143A | イシン | グロース | 91.0 | +342% | +4,325% | 17.6% | 14.7% | [株探](https://kabutan.jp/stock/?code=143A) |
```

### 3. 各セクションの表示カラム

| セクション | カラム |
|-----------|--------|
| B-1 連続増収増益 | ティッカー, 銘柄, 市場, セクター, リンク |
| B-2 営業利益率改善 | ティッカー, 銘柄, 市場, 最新利益率, 改善幅(pp), リンク |
| B-3 業績予想上方修正 | ティッカー, 銘柄, 市場, 利益修正率, 売上修正率, リンク |
| B-4 EPS成長率 | ティッカー, 銘柄, 市場, EPS成長率, 当期EPS, 前期EPS, リンク |
| C 財務健全性 | ティッカー, 銘柄, 市場, ROE, 自己資本比率, リンク |
| D-1 マルチファクター | ティッカー, 銘柄, 市場, 総合スコア, 売上成長, 利益成長, 営業利益率, ROE, リンク |
| D-2 セクター偏差値 | ティッカー, 銘柄, 市場, 偏差値, セクター内順位, リンク |

### 4. レポートヘッダー

```markdown
# スクリーニング結果レポート

- 実行日: {YYYY-MM-DD}
- データ: {total_companies}社 / {total_statements}件の決算データ
- 比較対象: 通期決算（FY）のみ / 前期黒字企業のみ
- リンク: [株探（Kabutan）](https://kabutan.jp/)
```

## パラメータのカスタマイズ

ユーザーがスクリーニング条件を指定した場合、`run_screening.sh` のデフォルトパラメータではなく curl で直接エンドポイントを叩いてカスタム条件で実行する。

主要パラメータ:
- `min_periods`: 連続期数（デフォルト: 3）
- `min_margin_change`: 利益率改善幅pp（デフォルト: 1.0）
- `min_revision_pct`: 修正率%（デフォルト: 10）
- `min_eps_growth`: EPS成長率%（デフォルト: 20）
- `min_equity_ratio`: 自己資本比率%（デフォルト: 50）
- `min_roe`: ROE%（デフォルト: 10）
- `sector`: セクター33コードでフィルタ
- `market`: 市場名でフィルタ（プライム, スタンダード, グロース）
- `limit`: 取得件数（デフォルト: 20, 最大: 500）
