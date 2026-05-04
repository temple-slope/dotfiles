---
name: skillmap
description: skillsmp.com（通称 SkillMap）に接続し、Claude Skill のキーワード検索 / AI セマンティック検索 / SKILL.md プレビューを行う。「SkillMap で探して」「skill を検索して」「skillmap_search」「ai-search」と言われたら使用する。
metadata:
  {
    "openclaw":
      {
        "emoji": "🗺️",
        "requires": { "bins": ["curl", "jq"], "env": ["SKILLSMP_API_KEY"] },
      },
  }
---

# SkillMap (skillsmp.com) Skill

skillsmp.com の REST API を叩き、Claude/Agent Skill を発見するためのスキル。
公式名は **SkillsMP**（skillsmp.com）。本スキルでは別名「SkillMap」も同義として扱う。

## When to Use

✅ **USE this skill when:**

- ユーザーが「skill を検索」「skill を探して」「SkillMap で〜」と依頼した
- 自然言語で「〇〇できる skill ない？」と問われた（→ ai-search）
- カテゴリ／職業（SOC）で skill を絞り込みたい
- 検索結果の SKILL.md 中身をプレビューしたい

## When NOT to Use

❌ **DON'T use this skill when:**

- 既知の GitHub リポジトリを直接覗くだけ → `gh repo view` か `gh api` を直接使う
- 自前で skill を作成する → `example-skills:skill-creator` を使う
- 単に Web 上の skill 一覧を見たいだけ → `https://skillsmp.com` をブラウザで開く

## Setup

API キーは環境変数 `SKILLSMP_API_KEY` から読む。

```bash
# 確認
[ -n "$SKILLSMP_API_KEY" ] && echo "ok" || echo "missing SKILLSMP_API_KEY"
```

未設定なら `.zshenv` 等で `export SKILLSMP_API_KEY=sk_live_xxx` を追加し再ログイン。

### 認証ヘッダ

```
Authorization: Bearer $SKILLSMP_API_KEY
```

`search` は匿名でも可（50回/日・10回/分）、`ai-search` はキー必須（500回/日・30回/分）。

## エンドポイント

| エンドポイント                   | 認証 | 用途                                                     |
| -------------------------------- | ---- | -------------------------------------------------------- |
| `GET /api/v1/skills/search`      | 任意 | キーワード検索。`q`, `sortBy=stars\|recent`, `category`, `occupation`, `limit≤100`, `page` |
| `GET /api/v1/skills/ai-search`   | 必須 | 自然言語によるセマンティック検索。`q` のみ              |

レスポンスのヘッダに `X-RateLimit-Daily-Limit` / `X-RateLimit-Daily-Remaining` あり。
エラーコード: `INVALID_API_KEY` (401) / `MISSING_QUERY` (400) / `DAILY_QUOTA_EXCEEDED` (429)。

## 1. キーワード検索

URL エンコードは curl の `--data-urlencode` を使う（`-G` で GET に流す）。

```bash
curl -sS -G "https://skillsmp.com/api/v1/skills/search" \
  -H "Authorization: Bearer ${SKILLSMP_API_KEY}" \
  --data-urlencode "q=image generation" \
  --data-urlencode "sortBy=stars" \
  --data-urlencode "limit=20" \
  | jq -r '.data.skills[] | "\(.stars)\t\(.author)/\(.name)\t\(.githubUrl)"' \
  | column -t -s $'\t'
```

### よく使うフィルタ

```bash
# カテゴリ指定
... --data-urlencode "category=data-ai"

# 最近更新順
... --data-urlencode "sortBy=recent"

# ページング
... --data-urlencode "page=2" --data-urlencode "limit=50"
```

### 結果整形テンプレート

```bash
# Markdown 表で返す
jq -r '
  ["stars","author/name","description","githubUrl"],
  ["---","---","---","---"],
  (.data.skills[] | [.stars, "\(.author)/\(.name)", (.description[:80] + "..."), .githubUrl])
  | @tsv' \
  | column -t -s $'\t'
```

## 2. AI セマンティック検索

```bash
curl -sS -G "https://skillsmp.com/api/v1/skills/ai-search" \
  -H "Authorization: Bearer ${SKILLSMP_API_KEY}" \
  --data-urlencode "q=Claude で投資ポートフォリオのインフォグラフィックを作る skill" \
  | jq '.data.skills[] | {name, author, stars, githubUrl, description}'
```

`ai-search` は `q` のみ。`sortBy` 等は無効。

## 3. SKILL.md プレビュー

検索結果の `githubUrl` から SKILL.md 本文を取得する。
URL 形式: `https://github.com/<owner>/<repo>/tree/<branch>/<path>` 。

```bash
preview_skill() {
  local url="$1"  # githubUrl
  local raw="${url/github.com/raw.githubusercontent.com}"
  raw="${raw/\/tree\//\/}"
  curl -fsSL "${raw}/SKILL.md" || gh api "repos/${owner}/${repo}/contents/${path}/SKILL.md" --jq '.content' | base64 -d
}
```

実用上は `gh` を使うほうが安定（プライベートリポにも対応・レート制限管理済み）:

```bash
# githubUrl から owner/repo と path を抽出して gh で取得
URL="https://github.com/bytedance/deer-flow/tree/main/skills/public/image-generation"
PARTS="${URL#https://github.com/}"
OWNER_REPO="${PARTS%%/tree/*}"
REST="${PARTS#*/tree/}"
BRANCH="${REST%%/*}"
PATH_IN_REPO="${REST#*/}"

gh api "repos/${OWNER_REPO}/contents/${PATH_IN_REPO}/SKILL.md?ref=${BRANCH}" \
  --jq '.content' | base64 -d
```

## 4. 典型ワークフロー

1. `search` か `ai-search` で候補を 10〜20 件取得
2. ユーザーに表で提示し、関心のある skill を選んでもらう
3. 選ばれた skill の SKILL.md をプレビューして、採用可否を判断
4. 採用するなら GitHub から `git clone` または該当ディレクトリを `~/.local/share/chezmoi/dot_claude/skills/<name>/` にコピー → `chezmoi apply`

## Notes

- レート制限を超えそうなときは `X-RateLimit-Daily-Remaining` を必ず確認
- `q` には日本語を渡しても通る（URL エンコードは curl が処理）
- ドキュメント上、skill 詳細取得 / インストール API は **未提供**。続きは GitHub 側で完結させる
- `category` の取り得る値はドキュメントに列挙なし。試行錯誤で確認（例: `data-ai`, `devops`）
- 親リポの star 数 = 個別 skill の評価ではない点に注意（例: `bytedance/deer-flow` は 6万 star だが skill 単独の支持ではない）
