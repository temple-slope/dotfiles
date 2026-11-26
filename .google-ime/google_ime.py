#!/usr/bin/env python3
"""Google日本語入力の設定(config1.db)とユーザー辞書(user_dictionary.db)を
テキストから反映する。

どちらも protobuf バイナリ。管理対象のフィールドだけを書き換え、
それ以外のフィールドは元のバイト列のまま保持する。

定義の出典 (google/mozc):
  src/protocol/config.proto
  src/protocol/user_dictionary_storage.proto

Usage:
  google_ime.py config <config.toml> [--db PATH]
  google_ime.py dict <user_dictionary.tsv> [--db PATH]
"""

from __future__ import annotations

import argparse
import os
import secrets
import shutil
import sys
import tempfile
import tomllib
from datetime import datetime
from pathlib import Path

DATA_DIR = Path.home() / "Library/Application Support/Google/JapaneseInput"
BACKUP_KEEP = 5
MANAGED_DICT_NAME = "chezmoi"

# ---------------------------------------------------------------------------
# protobuf wire format (最小実装)
# ---------------------------------------------------------------------------

VARINT, I64, LEN, I32 = 0, 1, 2, 5


def _read_varint(buf: bytes, pos: int) -> tuple[int, int]:
    result = shift = 0
    while True:
        if pos >= len(buf):
            raise ValueError("truncated varint")
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, pos
        shift += 7


def _varint(n: int) -> bytes:
    if n < 0:
        n += 1 << 64
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def parse(buf: bytes) -> list[tuple[int, int, int | bytes, bytes]]:
    """(field番号, wire type, 値, 元のバイト列) のリストを返す。"""
    fields = []
    pos = 0
    while pos < len(buf):
        start = pos
        tag, pos = _read_varint(buf, pos)
        num, wt = tag >> 3, tag & 7
        if wt == VARINT:
            val, pos = _read_varint(buf, pos)
        elif wt == I64:
            val, pos = buf[pos : pos + 8], pos + 8
        elif wt == LEN:
            length, pos = _read_varint(buf, pos)
            val, pos = buf[pos : pos + length], pos + length
        elif wt == I32:
            val, pos = buf[pos : pos + 4], pos + 4
        else:
            raise ValueError(f"unsupported wire type {wt}")
        if pos > len(buf):
            raise ValueError("truncated field")
        fields.append((num, wt, val, buf[start:pos]))
    return fields


def enc_varint(num: int, val: int) -> bytes:
    return _varint(num << 3 | VARINT) + _varint(val)


def enc_bytes(num: int, val: bytes) -> bytes:
    return _varint(num << 3 | LEN) + _varint(len(val)) + val


def enc_str(num: int, val: str) -> bytes:
    return enc_bytes(num, val.encode("utf-8"))


def replace_fields(buf: bytes, replacements: dict[int, bytes]) -> bytes:
    """指定フィールド(繰り返し含む)を置換する。最初の出現位置に挿入し、
    存在しなければ末尾に追加。他フィールドはバイト列のまま保持。"""
    out = bytearray()
    done: set[int] = set()
    for num, _wt, _val, raw in parse(buf):
        if num in replacements:
            if num not in done:
                out += replacements[num]
                done.add(num)
        else:
            out += raw
    for num, data in replacements.items():
        if num not in done:
            out += data
    return bytes(out)


# ---------------------------------------------------------------------------
# ファイル書き込み
# ---------------------------------------------------------------------------


def write_db(db: Path, data: bytes) -> None:
    old = db.read_bytes() if db.exists() else None
    if old == data:
        print(f"unchanged: {db}")
        return
    if old is not None:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copy2(db, db.with_name(f"{db.name}.bak.{stamp}"))
        backups = sorted(db.parent.glob(f"{db.name}.bak.*"))
        for stale in backups[:-BACKUP_KEEP]:
            stale.unlink()
    fd, tmp = tempfile.mkstemp(dir=db.parent, prefix=f".{db.name}.")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
        if old is not None:
            shutil.copymode(db, tmp)
        else:
            os.chmod(tmp, 0o644)
        os.replace(tmp, db)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise
    print(f"updated: {db}")


# ---------------------------------------------------------------------------
# config1.db
# ---------------------------------------------------------------------------

# config.proto のフィールド番号
F_SESSION_KEYMAP = 41
F_CUSTOM_KEYMAP_TABLE = 42
F_CUSTOM_ROMAN_TABLE = 43
F_SPACE_CHARACTER_FORM = 47
F_CHARACTER_FORM_RULES = 54

KEYMAP = {"custom": 0, "atok": 1, "msime": 2, "kotoeri": 3}
SPACE_FORM = {"input_mode": 0, "full": 1, "half": 2}
CHAR_FORM = {"half": 0, "full": 1, "last": 2, "no_conversion": 3}


def _lookup(table: dict[str, int], key: str, what: str) -> int:
    try:
        return table[key]
    except KeyError:
        raise ValueError(f"{what}: unknown value {key!r} (choices: {', '.join(table)})") from None


def build_config(old: bytes, conf: dict) -> bytes:
    rules = conf.get("character_form_rules", [])
    if not rules:
        raise ValueError("character_form_rules is empty")
    rules_bytes = b"".join(
        enc_bytes(
            F_CHARACTER_FORM_RULES,
            enc_str(1, r["group"])
            + enc_varint(2, _lookup(CHAR_FORM, r["preedit"], "preedit"))
            + enc_varint(3, _lookup(CHAR_FORM, r["conversion"], "conversion")),
        )
        for r in rules
    )
    replacements = {
        F_SESSION_KEYMAP: enc_varint(F_SESSION_KEYMAP, _lookup(KEYMAP, conf["keymap"], "keymap")),
        # 空 = 独自キーマップ/ローマ字テーブルなし(標準を使う)
        F_CUSTOM_KEYMAP_TABLE: enc_bytes(F_CUSTOM_KEYMAP_TABLE, b""),
        F_CUSTOM_ROMAN_TABLE: b"",
        F_SPACE_CHARACTER_FORM: enc_varint(
            F_SPACE_CHARACTER_FORM, _lookup(SPACE_FORM, conf["space_character_form"], "space_character_form")
        ),
        F_CHARACTER_FORM_RULES: rules_bytes,
    }
    return replace_fields(old, replacements)


def cmd_config(args: argparse.Namespace) -> None:
    with open(args.source, "rb") as f:
        conf = tomllib.load(f)
    db = Path(args.db)
    if not db.exists():
        # 一度も起動していない環境。IME が初回起動時に生成するまで待つ
        print(f"skip: {db} not found (start Google Japanese Input once)")
        return
    write_db(db, build_config(db.read_bytes(), conf))


# ---------------------------------------------------------------------------
# user_dictionary.db
# ---------------------------------------------------------------------------

# user_dictionary_storage.proto の PosType
POS = {
    "品詞なし": 0, "名詞": 1, "短縮よみ": 2, "サジェストのみ": 3, "固有名詞": 4,
    "人名": 5, "姓": 6, "名": 7, "組織": 8, "地名": 9, "名詞サ変": 10,
    "名詞形動": 11, "数": 12, "アルファベット": 13, "記号": 14, "顔文字": 15,
    "副詞": 16, "連体詞": 17, "接続詞": 18, "感動詞": 19, "接頭語": 20,
    "助数詞": 21, "接尾一般": 22, "接尾人名": 23, "接尾地名": 24,
    "動詞ワ行五段": 25, "動詞カ行五段": 26, "動詞サ行五段": 27,
    "動詞タ行五段": 28, "動詞ナ行五段": 29, "動詞マ行五段": 30,
    "動詞ラ行五段": 31, "動詞ガ行五段": 32, "動詞バ行五段": 33,
    "動詞ハ行四段": 34, "動詞一段": 35, "動詞カ変": 36, "動詞サ変": 37,
    "動詞ザ変": 38, "動詞ラ変": 39, "形容詞": 40, "終助詞": 41,
    "句読点": 42, "独立語": 43, "抑制単語": 44,
}

# UserDictionaryStorage / UserDictionary のフィールド番号
F_DICTIONARIES = 2
F_DICT_ID, F_DICT_NAME, F_DICT_ENTRIES = 1, 3, 4


def parse_tsv(path: Path) -> list[bytes]:
    entries, errors = [], []
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) < 3 or len(cols) > 4 or not cols[0] or not cols[1]:
            errors.append(f"{path}:{lineno}: expected 'よみ<TAB>単語<TAB>品詞[<TAB>コメント]'")
            continue
        if cols[2] not in POS:
            errors.append(f"{path}:{lineno}: unknown 品詞 {cols[2]!r}")
            continue
        comment = cols[3] if len(cols) == 4 else ""
        entries.append(
            enc_str(1, cols[0]) + enc_str(2, cols[1]) + enc_str(4, comment) + enc_varint(5, POS[cols[2]])
        )
    if errors:
        raise ValueError("\n".join(errors))
    return entries


def build_dict(old: bytes, entries: list[bytes]) -> bytes:
    dict_id = None
    for num, wt, val, _raw in parse(old):
        if num == F_DICTIONARIES and wt == LEN:
            sub = parse(val)
            if any(n == F_DICT_NAME and v == MANAGED_DICT_NAME.encode() for n, _w, v, _r in sub):
                dict_id = next((v for n, w, v, _r in sub if n == F_DICT_ID and w == VARINT), None)
    if dict_id is None:
        dict_id = secrets.randbits(63) or 1
    managed = enc_bytes(
        F_DICTIONARIES,
        enc_varint(F_DICT_ID, dict_id)
        + enc_str(F_DICT_NAME, MANAGED_DICT_NAME)
        + b"".join(enc_bytes(F_DICT_ENTRIES, e) for e in entries),
    )
    # 管理辞書を除いた既存辞書はそのまま、管理辞書を末尾に置く
    out = bytearray()
    for num, wt, val, raw in parse(old):
        if num == F_DICTIONARIES and wt == LEN:
            if any(n == F_DICT_NAME and v == MANAGED_DICT_NAME.encode() for n, _w, v, _r in parse(val)):
                continue
        out += raw
    return bytes(out) + managed


def cmd_dict(args: argparse.Namespace) -> None:
    entries = parse_tsv(Path(args.source))
    db = Path(args.db)
    if not db.parent.is_dir():
        print(f"skip: {db.parent} not found")
        return
    old = db.read_bytes() if db.exists() else b""
    write_db(db, build_dict(old, entries))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("config", help="config1.db に設定を反映")
    p.add_argument("source")
    p.add_argument("--db", default=str(DATA_DIR / "config1.db"))
    p.set_defaults(func=cmd_config)
    p = sub.add_parser("dict", help="user_dictionary.db に辞書を反映")
    p.add_argument("source")
    p.add_argument("--db", default=str(DATA_DIR / "user_dictionary.db"))
    p.set_defaults(func=cmd_dict)
    args = parser.parse_args()
    try:
        args.func(args)
    except (ValueError, KeyError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
