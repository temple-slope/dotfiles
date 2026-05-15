/**
 * Fetch a specific X (Twitter) post and its full thread using xAI (Grok) + x_search.
 *
 * - Accepts a tweet URL or tweet ID and returns the post with full thread context.
 * - Saves artifacts under ~/Documents/Development/claude-output/x-tweet-fetch/ (json/txt/md).
 *
 * Requires:
 *   XAI_API_KEY in env or .env
 *
 * Usage:
 *   npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123456"
 *   npx tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123456" --replies
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

type Json = null | boolean | number | string | Json[] | { [k: string]: Json };

const DEFAULT_BASE_URL = 'https://api.x.ai';
const DEFAULT_MODEL = 'grok-4-1-fast-reasoning';

function repoRoot(): string {
  const __filename = fileURLToPath(import.meta.url);
  return path.resolve(path.dirname(__filename), '..');
}

function loadDotenv(dotenvPath: string): Record<string, string> {
  if (!fs.existsSync(dotenvPath)) return {};
  const out: Record<string, string> = {};
  const lines = fs.readFileSync(dotenvPath, 'utf8').split(/\r?\n/);
  for (const raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq === -1) continue;
    const k = line.slice(0, eq).trim();
    let v = line.slice(eq + 1).trim();
    if (!k) continue;
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    out[k] = v;
  }
  return out;
}

function timestampSlug(d: Date): string {
  const iso = d.toISOString();
  return `${iso.slice(0, 4)}${iso.slice(5, 7)}${iso.slice(8, 10)}_${iso.slice(11, 13)}${iso.slice(14, 16)}${iso.slice(17, 19)}Z`;
}

interface ParsedUrl {
  handle: string;
  tweetId: string;
}

function parseTweetUrl(raw: string): ParsedUrl | null {
  const cleaned = raw.trim().replace(/\?.*$/, '');
  const m = cleaned.match(/(?:x\.com|twitter\.com)\/([^/]+)\/status\/(\d+)/);
  if (!m) return null;
  return { handle: `@${m[1]}`, tweetId: m[2] };
}

function parseArgs(argv: string[]) {
  const args = {
    url: '',
    replies: false,
    out_dir: path.join(os.homedir(), 'Documents/Development/claude-output/x-tweet-fetch'),
    xai_api_key: '',
    xai_base_url: '',
    xai_model: '',
    dry_run: false,
    raw_json: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => (i + 1 < argv.length ? argv[++i] : '');
    if (a === '--url') args.url = next();
    else if (a === '--replies') args.replies = true;
    else if (a === '--out-dir') args.out_dir = next() || args.out_dir;
    else if (a === '--xai_api_key') args.xai_api_key = next();
    else if (a === '--xai_base_url') args.xai_base_url = next();
    else if (a === '--xai_model') args.xai_model = next();
    else if (a === '--dry-run') args.dry_run = true;
    else if (a === '--raw-json') args.raw_json = true;
    else if (a === '-h' || a === '--help') {
      // eslint-disable-next-line no-console
      console.log(`Usage:
  tsx dot_claude/scripts/grok_tweet_fetch.ts --url "https://x.com/user/status/123"

Options:
  --url URL         tweet URL (required, x.com or twitter.com)
  --replies         also fetch notable replies (default: thread only)
  --out-dir DIR     output directory (default: ~/Documents/Development/claude-output/x-tweet-fetch)
  --dry-run         print request payload and exit
  --raw-json        also print raw JSON response to stderr
`);
      process.exit(0);
    }
  }

  return args;
}

function getConfig(args: ReturnType<typeof parseArgs>) {
  const dotenv = loadDotenv(path.join(repoRoot(), '.env'));
  const getStr = (envKey: string, cliValue: string, fallback: string) =>
    cliValue || process.env[envKey] || dotenv[envKey] || fallback;

  const xai_api_key = getStr('XAI_API_KEY', args.xai_api_key, '');
  const xai_base_url = getStr('XAI_BASE_URL', args.xai_base_url, DEFAULT_BASE_URL).replace(
    /\/+$/,
    '',
  );
  const xai_model = getStr('XAI_MODEL', args.xai_model, DEFAULT_MODEL);

  return { xai_api_key, xai_base_url, xai_model };
}

function buildPrompt(input: {
  handle: string;
  tweetId: string;
  url: string;
  replies: boolean;
  nowIso: string;
}): string {
  const repliesSection = input.replies
    ? `
6) 主要なリプライ（いいね数が多い、影響力のあるアカウントからの返信）も収集する:
   - リプライ投稿者
   - 本文
   - いいね数
   - リプライURL`
    : '';

  return `日本語で回答して。

目的: 特定のXポストとそのスレッド全体を取得し、構造化された情報を出力する。
対象ポスト: ${input.url}
投稿者: ${input.handle}
ツイートID: ${input.tweetId}
時点: ${input.nowIso}

やること:
1) x_search を使って上記のポストを特定し、全文を取得する
2) このポストがスレッド（連投）の一部である場合、スレッド全体を時系列順に取得する
3) 引用元や参照先のポストがある場合、それも追跡する
4) 各ポストについて以下の情報を抽出する:
   - 投稿者（ハンドル名、表示名）
   - 投稿日時（UTC）
   - 本文（全文。省略しない）
   - いいね数
   - リポスト数（RT数）
   - 引用数（取得可能な場合）
   - リプライ数（取得可能な場合）
   - 閲覧数（取得可能な場合）
   - メディア有無（画像/動画/リンクカード）
   - ポストURL
5) 取得できなかった数値は "N/A" と記載する${repliesSection}

出力形式（Markdown）:

## Post Info
- Author: {表示名} (${input.handle})
- Posted: {投稿日時 UTC}
- URL: ${input.url}
- Tweet ID: ${input.tweetId}
- Fetched at: {取得日時 UTC}

## Engagement
| Likes | RTs | Quotes | Replies | Views |
|-------|-----|--------|---------|-------|
| {数}  | {数} | {数}  | {数}    | {数}  |

## Content
{本文全文}

## Media
{メディアの説明。なければ "なし"}

## Thread
{スレッドがある場合、時系列順に各ポストを記載。ない場合は "単独ポスト（スレッドなし）"}

### {番号}/{全体数} - {投稿日時}
{本文}
| Likes | RTs | Quotes | Replies | Media |
|-------|-----|--------|---------|-------|
| {数}  | {数} | {数}  | {数}    | {有無} |
URL: {URL}

---
${
  input.replies
    ? `
## Notable Replies
{いいね数の多い順に主要リプライを記載}

### @{リプライ投稿者} - {日時}
{本文}
Likes: {数} | URL: {URL}

---
`
    : ''
}
## Context
- 引用元/参照先ポスト（ある場合）
- 関連する背景情報（ある場合）

注意:
- 数字/エンゲージメントは捏造しない。不明は N/A と書く
- 出力に専用タグ（render_inline_citation など）を入れない。URLは素のURLで書く
- ポスト本文は原文を尊重し、意味を変える要約はしない
`;
}

async function postJson(
  url: string,
  headers: Record<string, string>,
  payload: Json,
  timeoutMs: number,
): Promise<unknown> {
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload),
      signal: ac.signal,
    });
    const text = await res.text();
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${text.slice(0, 4000)}`);
    }
    return JSON.parse(text) as unknown;
  } finally {
    clearTimeout(t);
  }
}

function extractText(resp: unknown): string {
  if (resp && typeof resp === 'object') {
    const r = resp as { [k: string]: unknown };
    const out = r['output'];
    if (Array.isArray(out)) {
      const parts: string[] = [];
      for (const item of out) {
        if (!item || typeof item !== 'object') continue;
        const content = (item as { [k: string]: unknown })['content'];
        if (!Array.isArray(content)) continue;
        for (const c of content) {
          if (!c || typeof c !== 'object') continue;
          const t = (c as { [k: string]: unknown })['text'];
          if (typeof t === 'string' && t.trim()) parts.push(t);
        }
      }
      if (parts.length) return parts.join('\n').trim();
    }
    for (const k of ['output_text', 'text', 'content']) {
      const v = r[k];
      if (typeof v === 'string' && v.trim()) return v.trim();
    }
  }
  return JSON.stringify(resp, null, 2);
}

function saveFile(outDir: string, filename: string, content: string) {
  const root = repoRoot();
  const absDir = path.isAbsolute(outDir) ? outDir : path.join(root, outDir);
  fs.mkdirSync(absDir, { recursive: true });
  const p = path.join(absDir, filename);
  fs.writeFileSync(p, content, 'utf8');
  return p;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const cfg = getConfig(args);

  if (!cfg.xai_api_key.trim()) {
    // eslint-disable-next-line no-console
    console.error('Missing XAI_API_KEY. Set it in .env or environment.');
    process.exit(2);
  }
  if (!args.url.trim()) {
    // eslint-disable-next-line no-console
    console.error('Missing --url. Example: --url "https://x.com/user/status/123456"');
    process.exit(2);
  }

  const parsed = parseTweetUrl(args.url);
  if (!parsed) {
    // eslint-disable-next-line no-console
    console.error(`Invalid tweet URL: ${args.url}`);
    console.error('Expected format: https://x.com/{user}/status/{id}');
    process.exit(2);
  }

  const now = new Date();
  const prompt = buildPrompt({
    handle: parsed.handle,
    tweetId: parsed.tweetId,
    url: args.url.trim(),
    replies: args.replies,
    nowIso: now.toISOString(),
  });

  const payload: Json = {
    model: cfg.xai_model,
    input: prompt,
    tools: [{ type: 'x_search' }],
  };

  if (args.dry_run) {
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(payload, null, 2));
    return;
  }

  const url = `${cfg.xai_base_url}/v1/responses`;
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${cfg.xai_api_key}`,
  };

  const resp = await postJson(url, headers, payload, 180_000);
  const text = extractText(resp);

  const ts = timestampSlug(now);
  const slug = `${parsed.handle.replace(/^@/, '').toLowerCase()}_${parsed.tweetId}`;
  const base = `${ts}_${slug}`;
  const md = `# X Post: ${parsed.handle}/status/${parsed.tweetId}\n\n## Meta\n- URL: ${args.url.trim()}\n- Author: ${parsed.handle}\n- Tweet ID: ${parsed.tweetId}\n- Fetched at (UTC): ${now.toISOString()}\n- Include replies: ${args.replies}\n\n---\n\n${text}\n`;

  const jsonFile = saveFile(
    args.out_dir,
    `${base}.json`,
    JSON.stringify(
      {
        timestamp: now.toISOString(),
        url: args.url.trim(),
        handle: parsed.handle,
        tweet_id: parsed.tweetId,
        params: {
          replies: args.replies,
          model: cfg.xai_model,
          base_url: cfg.xai_base_url,
          out_dir: args.out_dir,
        },
        request: payload,
        response: resp,
        extracted_text: text,
      },
      null,
      2,
    ),
  );
  const txtFile = saveFile(args.out_dir, `${base}.txt`, text);
  const mdFile = saveFile(args.out_dir, `${base}.md`, md);

  // eslint-disable-next-line no-console
  console.error(`Saved: ${path.relative(process.cwd(), jsonFile)}`);
  // eslint-disable-next-line no-console
  console.error(`Saved: ${path.relative(process.cwd(), txtFile)}`);
  // eslint-disable-next-line no-console
  console.error(`Saved: ${path.relative(process.cwd(), mdFile)}`);

  if (args.raw_json) {
    // eslint-disable-next-line no-console
    console.error(JSON.stringify(resp, null, 2));
  }

  // eslint-disable-next-line no-console
  console.log(text);
}

main().catch((err: unknown) => {
  // eslint-disable-next-line no-console
  console.error(String(err));
  process.exit(1);
});
