# bitbankの公開APIを利用する簡易モジュール
# curlとpython3が利用可能であることを前提としています。

# bitbanck_ticker <通貨ペア>
# 例: bitbanck_ticker btc_jpy
bitbanck_ticker() {
  if ! command -v curl >/dev/null 2>&1; then
    print -u2 "bitbanck_ticker: curlが見つかりません"
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    print -u2 "bitbanck_ticker: python3が見つかりません"
    return 1
  fi

  local pair="${1:-btc_jpy}"
  local endpoint="https://public.bitbank.cc/${pair}/ticker"
  local response

  if ! response="$(curl -fsS "$endpoint" 2>/dev/null)"; then
    print -u2 "bitbanck_ticker: APIリクエストに失敗しました"
    return 1
  fi

  BITBANCK_RESPONSE="$response" python3 - "$pair" <<'PY'
import datetime as dt
import json
import os
import sys

pair = sys.argv[1]
raw = os.environ.get("BITBANCK_RESPONSE", "")

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("bitbanck_ticker: レスポンスの解析に失敗しました", file=sys.stderr)
    sys.exit(1)

if not data.get("success"):
    print("bitbanck_ticker: APIレスポンスがエラーです", file=sys.stderr)
    sys.exit(1)

ticker = data.get("data", {})
try:
    timestamp = dt.datetime.fromtimestamp(int(ticker.get("timestamp", 0)) / 1000)
except (TypeError, ValueError):
    timestamp = None

last = ticker.get("last", "-")
high = ticker.get("high", "-")
low = ticker.get("low", "-")
volume = ticker.get("volume", "-")

if timestamp is None:
    print(f"{pair} 最終取引価格: {last} / 高値: {high} / 安値: {low} / 取引量: {volume}")
else:
    formatted = timestamp.strftime("%Y-%m-%d %H:%M:%S")
    print(f"{pair} 最終取引価格: {last} / 高値: {high} / 安値: {low} / 取引量: {volume} @ {formatted}")
PY
}

# bitbanck_pairs
# 取扱い中の通貨ペア一覧を取得します。
bitbanck_pairs() {
  if ! command -v curl >/dev/null 2>&1; then
    print -u2 "bitbanck_pairs: curlが見つかりません"
    return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    print -u2 "bitbanck_pairs: python3が見つかりません"
    return 1
  fi

  local endpoint="https://public.bitbank.cc/tickers"
  local response

  if ! response="$(curl -fsS "$endpoint" 2>/dev/null)"; then
    print -u2 "bitbanck_pairs: APIリクエストに失敗しました"
    return 1
  fi

  BITBANCK_RESPONSE="$response" python3 - <<'PY'
import json
import os
import sys

raw = os.environ.get("BITBANCK_RESPONSE", "")

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("bitbanck_pairs: レスポンスの解析に失敗しました", file=sys.stderr)
    sys.exit(1)

if not data.get("success"):
    print("bitbanck_pairs: APIレスポンスがエラーです", file=sys.stderr)
    sys.exit(1)

pairs = data.get("data", {}).get("pairs", [])
for item in pairs:
    pair = item.get("name")
    if pair:
        print(pair)
PY
}
