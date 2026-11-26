#!/usr/bin/env python3
"""AI のレート制限使用量を集約して 1 行で表示する（herdr のタブバー用）。

Usage:
  ai_usage.py record <provider>   stdin の生 JSON を正規化してキャッシュへ保存（push 型）
  ai_usage.py show                設定のプロバイダーを並べて 1 行出力

プロバイダーの追加:
  1. ADAPTERS に record（push 型: 生 JSON → windows）か collect（pull 型: 自分で読みに行く）を足す
  2. ~/.config/ai-usage/config.json の providers に 1 項目足す

正規化形式 (~/.cache/ai-usage/<provider>.json):
  {"provider": str, "updated_at": epoch,
   "windows": [{"label": "5h", "used_percent": float, "resets_at": epoch|null}, ...]}
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

CONFIG_PATH = Path(__file__).resolve().with_name("config.json")
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "ai-usage"

BLOCKS = " ▏▎▍▌▋▊▉█"
ICONS = {"5h": "⏳", "7d": "\U0001f4c5"}

Window = dict  # {"label", "used_percent", "resets_at"}


# ---------------------------------------------------------------------------
# 共通
# ---------------------------------------------------------------------------


def window_label(minutes: int | None) -> str:
    if not minutes:
        return "?"
    if minutes % 1440 == 0:
        return f"{minutes // 1440}d"
    if minutes % 60 == 0:
        return f"{minutes // 60}h"
    return f"{minutes}m"


def write_cache(provider: str, windows: list[Window]) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    payload = {"provider": provider, "updated_at": int(time.time()), "windows": windows}
    fd, tmp = tempfile.mkstemp(dir=CACHE_DIR, prefix=f".{provider}.")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(payload, f)
        os.replace(tmp, CACHE_DIR / f"{provider}.json")
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def read_cache(provider: str) -> dict | None:
    try:
        return json.loads((CACHE_DIR / f"{provider}.json").read_text())
    except (OSError, ValueError):
        return None


# ---------------------------------------------------------------------------
# アダプター
# ---------------------------------------------------------------------------


def claude_record(raw: dict) -> list[Window]:
    """Claude Code の statusline 入力の rate_limits から取り出す。"""
    limits = raw.get("rate_limits") or {}
    windows = []
    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        w = limits.get(key) or {}
        if w.get("used_percentage") is not None:
            windows.append({"label": label, "used_percent": w["used_percentage"], "resets_at": w.get("resets_at")})
    return windows


CODEX_SESSIONS = Path.home() / ".codex/sessions"
CODEX_SCAN_FILES = 5
CODEX_TAIL_BYTES = 512 * 1024


def codex_collect() -> list[Window] | None:
    """最新の Codex セッションログから最後の rate_limits を読む。"""
    files = sorted(CODEX_SESSIONS.glob("*/*/*/rollout-*.jsonl"), reverse=True)[:CODEX_SCAN_FILES]
    for path in files:
        try:
            with path.open("rb") as f:
                f.seek(max(0, path.stat().st_size - CODEX_TAIL_BYTES))
                lines = f.read().decode("utf-8", "replace").splitlines()
        except OSError:
            continue
        for line in reversed(lines):
            if '"rate_limits"' not in line:
                continue
            try:
                limits = json.loads(line).get("payload", {}).get("rate_limits") or {}
            except ValueError:
                continue
            windows = [
                {"label": window_label(w.get("window_minutes")), "used_percent": w["used_percent"], "resets_at": w.get("resets_at")}
                for w in (limits.get("primary"), limits.get("secondary"))
                if w and w.get("used_percent") is not None
            ]
            if windows:
                return windows
    return None


ADAPTERS: dict[str, dict] = {
    "claude": {"record": claude_record},
    "codex": {"collect": codex_collect},
}


# ---------------------------------------------------------------------------
# 表示
# ---------------------------------------------------------------------------


def bar(pct: float, width: int = 10) -> str:
    pct = min(max(pct, 0), 100)
    filled = pct * width / 100
    full = int(filled)
    frac = int((filled - full) * 8)
    b = "█" * full
    if full < width:
        b += BLOCKS[frac] + "░" * (width - full - 1)
    return b


def fmt_window(w: Window, now: float) -> str:
    pct = w.get("used_percent") or 0
    resets_at = w.get("resets_at")
    if resets_at and resets_at <= now:
        pct, resets_at = 0, None  # 窓がリセット済み。古い値を出さない
    label = w.get("label", "?")
    icon = ICONS.get(label)
    seg = f"{icon} {label}" if icon else label
    seg += f" {bar(pct)} {round(pct)}%"
    if resets_at:
        dt = datetime.fromtimestamp(resets_at)
        seg += " ↻" + (dt.strftime("%H:%M") if resets_at - now < 86400 else f"{dt.month}/{dt.day} {dt:%H:%M}")
    return seg


def load_provider(pid: str) -> dict | None:
    adapter = ADAPTERS.get(pid, {})
    if "collect" in adapter:
        windows = adapter["collect"]()
        return {"updated_at": time.time(), "windows": windows} if windows else None
    return read_cache(pid)


def show() -> str:
    try:
        conf = json.loads(CONFIG_PATH.read_text())
    except (OSError, ValueError):
        conf = {"providers": [{"id": pid} for pid in ADAPTERS]}
    stale = conf.get("stale_hours", 6) * 3600
    now = time.time()
    parts = []
    for p in conf.get("providers", []):
        try:
            data = load_provider(p["id"])
        except Exception:
            continue
        if not data or not data.get("windows"):
            continue
        name = p.get("name", p["id"])
        if now - data.get("updated_at", 0) > stale:
            name += "?"
        parts.append(name + " " + " │ ".join(fmt_window(w, now) for w in data["windows"]))
    return " ┃ ".join(parts)


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "show":
        print(show())
        return 0
    if len(sys.argv) == 3 and sys.argv[1] == "record":
        # statusline から呼ばれるので失敗しても黙って終わる
        try:
            record = ADAPTERS[sys.argv[2]]["record"]
            windows = record(json.load(sys.stdin))
            if windows:
                write_cache(sys.argv[2], windows)
        except Exception:
            pass
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
