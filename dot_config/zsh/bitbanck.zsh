# bitbankの公開APIを利用する簡易モジュール
# curlとpython3が利用可能であることを前提としています。

__bitbanck_curl() {
  local endpoint="$1"
  local user_agent="${BITBANCK_USER_AGENT:-bitbanck.zsh/1.0}"
  curl -fsSL --retry 2 --retry-delay 1 --connect-timeout 10 -A "$user_agent" "$endpoint"
}

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

  if ! response="$(__bitbanck_curl "$endpoint" 2>/dev/null)"; then
    print -u2 "bitbanck_ticker: APIリクエストに失敗しました"
    return 1
  fi

  print -r -- "$response" | python3 - "$pair" <<'PY'
import datetime as dt
import json
import sys

pair = sys.argv[1]
raw = sys.stdin.read()

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

  local response
  local endpoint_pairs="https://public.bitbank.cc/pairs"
  local endpoint_tickers="https://public.bitbank.cc/tickers"

  if ! response="$(__bitbanck_curl "$endpoint_pairs" 2>/dev/null)"; then
    if ! response="$(__bitbanck_curl "$endpoint_tickers" 2>/dev/null)"; then
      print -u2 "bitbanck_pairs: APIリクエストに失敗しました"
      return 1
    fi
  fi

  print -r -- "$response" | python3 - <<'PY'
import json
import sys

raw = sys.stdin.read()

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("bitbanck_pairs: レスポンスの解析に失敗しました", file=sys.stderr)
    sys.exit(1)

if not data.get("success"):
    print("bitbanck_pairs: APIレスポンスがエラーです", file=sys.stderr)
    sys.exit(1)

payload = data.get("data", {})

def iter_pairs(obj):
    if isinstance(obj, dict):
        if "pairs" in obj and isinstance(obj["pairs"], (list, tuple)):
            for entry in obj["pairs"]:
                yield from iter_pairs(entry)
        elif "name" in obj and isinstance(obj["name"], str):
            yield obj["name"]
        elif "code" in obj and isinstance(obj["code"], str):
            yield obj["code"]
    elif isinstance(obj, (list, tuple)):
        for entry in obj:
            yield from iter_pairs(entry)
    elif isinstance(obj, str):
        yield obj

pairs = list(dict.fromkeys(iter_pairs(payload)))

if not pairs:
    print("bitbanck_pairs: 通貨ペア情報が見つかりません", file=sys.stderr)
    sys.exit(1)

for pair in pairs:
    print(pair)
PY
}
