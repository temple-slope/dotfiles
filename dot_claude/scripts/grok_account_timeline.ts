/**
 * Fetch recent posts from a specific X (Twitter) account using xAI (Grok) + x_search.
 *
 * - Accepts an account handle and returns a structured timeline of recent posts.
 * - Saves artifacts under ~/Documents/Development/claude-output/x-account-watch/ (json/txt/md).
 *
 * Requires:
 *   XAI_API_KEY in env or .env
 *
 * Usage:
 *   npx tsx dot_claude/scripts/grok_account_timeline.ts --account "@anthropikirai"
 *   npx tsx dot_claude/scripts/grok_account_timeline.ts --account "@elaborai" --count 10 --days 7
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
  const y = iso.slice(0, 4);
  const m = iso.slice(5, 7);
  const day = iso.slice(8, 10);
  const hh = iso.slice(11, 13);
  const mm = iso.slice(14, 16);
  const ss = iso.slice(17, 19);
  return `${y}${m}${day}_${hh}${mm}${ss}Z`;
}

function parseArgs(argv: string[]) {
  const args = {
    account: '',
    count: 20,
    days: 7,
    out_dir: path.join(os.homedir(), 'Documents/Development/claude-output/x-account-watch'),
    xai_api_key: '',
    xai_base_url: '',
    xai_model: '',
    dry_run: false,
    raw_json: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => (i + 1 < argv.length ? argv[++i] : '');
    if (a === '--account') args.account = next();
    else if (a === '--count') args.count = Number(next());
    else if (a === '--days') args.days = Number(next());
    else if (a === '--out-dir') args.out_dir = next() || args.out_dir;
    else if (a === '--xai_api_key') args.xai_api_key = next();
    else if (a === '--xai_base_url') args.xai_base_url = next();
    else if (a === '--xai_model') args.xai_model = next();
    else if (a === '--dry-run') args.dry_run = true;
    else if (a === '--raw-json') args.raw_json = true;
    else if (a === '-h' || a === '--help') {
      // eslint-disable-next-line no-console
      console.log(`Usage:
  tsx dot_claude/scripts/grok_account_timeline.ts --account "@handle"

Options:
  --account HANDLE  X account to fetch (required, e.g. "@anthropikirai")
  --count N         number of recent posts to fetch (default: 20)
  --days N          lookback window in days (default: 7)
  --out-dir DIR     output directory (default: ~/Documents/Development/claude-output/x-account-watch)
  --dry-run         print request payload and exit
  --raw-json        also print raw JSON response to stderr
`);
      process.exit(0);
    }
  }

  if (!Number.isFinite(args.count) || args.count <= 0) args.count = 20;
  if (!Number.isFinite(args.days) || args.days <= 0) args.days = 7;
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
  account: string;
  count: number;
  days: number;
  nowIso: string;
}): string {
  return `日本語で回答して。

目的: 特定のXアカウントの最新ポストを取得し、構造化された一覧を作成する。
対象アカウント: ${input.account}
取得件数目安: 直近${input.count}件
検索窓: 直近${input.days}日
時点: ${input.nowIso}

やること:
1) x_search を使って ${input.account} の直近のポスト（ツイート）を取得する
2) リポスト（RT）は除外し、オリジナルポストと引用ポストのみ対象とする
3) スレッド（連投）がある場合はスレッド全体をまとめて1エントリとして扱う
4) 各ポストについて以下の情報を抽出する:
   - 投稿日時（UTC）
   - 本文（全文。長い場合も省略しない）
   - いいね数
   - リポスト数（RT数）
   - 引用数（取得可能な場合）
   - リプライ数（取得可能な場合）
   - メディア有無（画像/動画/リンクカード）
   - ポストURL
5) 取得できなかった数値は "N/A" と記載する

出力形式（Markdown）:

## Account Info
- Handle: ${input.account}
- Fetched at: {UTC タイムスタンプ}
- Posts found: {件数}

## Timeline

### {番号}. {投稿日時}
{本文全文}

| Likes | RTs | Quotes | Replies | Media |
|-------|-----|--------|---------|-------|
| {数}  | {数} | {数}  | {数}    | {有無} |

URL: {ポストURL}

---

（上記を各ポストについて繰り返す。新しい順に並べる）

## Summary
- 投稿頻度: {期間中の投稿ペース}
- 主なトピック: {よく言及しているテーマ3-5個}
- 最もエンゲージメントの高いポスト: {URL}

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

function accountSlug(account: string): string {
  return account.replace(/^@/, '').toLowerCase().replace(/[^a-z0-9_]/g, '');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const cfg = getConfig(args);

  if (!cfg.xai_api_key.trim()) {
    // eslint-disable-next-line no-console
    console.error('Missing XAI_API_KEY. Set it in .env or environment.');
    process.exit(2);
  }
  if (!args.account.trim()) {
    // eslint-disable-next-line no-console
    console.error('Missing --account. Example: --account "@anthropikirai"');
    process.exit(2);
  }

  const now = new Date();
  const prompt = buildPrompt({
    account: args.account.trim(),
    count: args.count,
    days: args.days,
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
  const slug = accountSlug(args.account);
  const base = `${ts}_${slug}`;
  const md = `# X Account Timeline: ${args.account}\n\n## Meta\n- Account: ${args.account}\n- Fetched at (UTC): ${now.toISOString()}\n- Count target: ${args.count}\n- Lookback: ${args.days} days\n\n---\n\n${text}\n`;

  const jsonFile = saveFile(
    args.out_dir,
    `${base}.json`,
    JSON.stringify(
      {
        timestamp: now.toISOString(),
        account: args.account.trim(),
        params: {
          count: args.count,
          days: args.days,
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
