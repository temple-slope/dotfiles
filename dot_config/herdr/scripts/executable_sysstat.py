#!/usr/bin/env python3
"""herdr のタブ行右端に出すシステム状態（以前の tmux の cpu | 󰍛 ram 相当）。

macmon（brew "macmon"、sudo 不要）があれば CPU/GPU/メモリ/温度/電力/ファン/ネットワーク/バッテリーを出す。
無ければ iostat / vm_stat / pmset で CPU・メモリ・バッテリーだけ出す。
herdr はサーバー環境の python3（macOS 標準 3.9）で実行するため、3.9 互換・標準ライブラリのみで書く。
取得できない項目は個別に省略し、常に exit 0 で 1 行出力する。
サーバーの PATH に /usr/sbin が無いことがあるため、OS のコマンドは絶対パスで呼ぶ。
"""

import json
import os
import re
import shutil
import subprocess

SEP = " │ "
MACMON_CANDIDATES = ["/opt/homebrew/bin/macmon", "/usr/local/bin/macmon"]


def run(args, timeout=3):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""


def find_macmon():
    found = shutil.which("macmon")
    if found:
        return found
    for path in MACMON_CANDIDATES:
        if os.access(path, os.X_OK):
            return path
    return None


def human_rate(n):
    for unit in ("B", "K", "M", "G"):
        if n < 1024 or unit == "G":
            return "{:.0f}{}".format(n, unit) if unit in ("B", "K") else "{:.1f}{}".format(n, unit)
        n /= 1024.0
    return ""


def pct(ratio):
    return "{}%".format(round(ratio * 100))


# ---------------------------------------------------------------------------
# macmon
# ---------------------------------------------------------------------------


def from_macmon(path):
    out = run([path, "pipe", "-s", "1", "-i", "500"])
    try:
        d = json.loads(out.strip().splitlines()[-1])
    except (ValueError, IndexError):
        return None
    parts = []
    if d.get("cpu_active_ratio") is not None:
        parts.append("\U0001f9e0 " + pct(d["cpu_active_ratio"]))
    if d.get("gpu_active_ratio") is not None:
        parts.append("\U0001f3ae " + pct(d["gpu_active_ratio"]))
    mem = d.get("memory") or {}
    if mem.get("ram_total"):
        seg = "\U0001f4be " + pct(mem["ram_usage"] / float(mem["ram_total"]))
        if mem.get("swap_usage"):
            seg += " swap {:.1f}G".format(mem["swap_usage"] / 1024.0 ** 3)
        parts.append(seg)
    temp = (d.get("temp") or {}).get("cpu_temp_avg")
    if temp:
        parts.append("\U0001f321 {}°C".format(round(temp)))
    if d.get("sys_power") is not None:
        parts.append("\U0001f50c {:.1f}W".format(d["sys_power"]))
    fans = [f for f in (d.get("fans") or []) if f.get("rpm") is not None]
    if fans:
        parts.append("\U0001f300 " + "/".join(str(f["rpm"]) for f in fans) + "rpm")
    if d.get("net_in") is not None and d.get("net_out") is not None:
        parts.append("\U0001f4e5 {} \U0001f4e4 {}".format(human_rate(d["net_in"]), human_rate(d["net_out"])))
    if d.get("battery_percent") is not None:
        parts.append(battery_seg(d["battery_percent"], bool(d.get("battery_charging"))))
    return parts


# ---------------------------------------------------------------------------
# フォールバック（macmon なし）
# ---------------------------------------------------------------------------


def cpu_iostat():
    lines = [l.split() for l in run(["/usr/sbin/iostat", "-c", "2", "-w", "1"]).splitlines() if l.strip()]
    try:
        header = next(l for l in lines if "id" in l)
        idle = float(lines[-1][header.index("id")])
        return "\U0001f9e0 {}%".format(round(100 - idle))
    except (StopIteration, ValueError, IndexError):
        return None


def mem_vm_stat():
    out = run(["/usr/bin/vm_stat"])
    m = re.search(r"page size of (\d+) bytes", out)
    stats = {k.strip(): int(v) for k, v in re.findall(r"^(.+?):\s+(\d+)\.$", out, re.M)}
    total = run(["/usr/sbin/sysctl", "-n", "hw.memsize"]).strip()
    try:
        used = (stats["Anonymous pages"] - stats["Pages purgeable"] + stats["Pages wired down"]
                + stats["Pages occupied by compressor"]) * int(m.group(1))
        return "\U0001f4be " + pct(used / float(total))
    except (KeyError, ValueError, AttributeError):
        return None


def battery_pmset():
    out = run(["/usr/bin/pmset", "-g", "batt"])
    m = re.search(r"(\d+)%;\s*(\w+)", out)
    if not m:
        return None
    return battery_seg(int(m.group(1)) / 100.0, m.group(2) == "charging")


def battery_seg(level, charging):
    if level > 1:  # macmon は 0-100、pmset 経由は 0-1
        level /= 100.0
    return "\U0001f50b " + pct(level) + ("⚡" if charging else "")


def main():
    parts = None
    macmon = find_macmon()
    if macmon:
        parts = from_macmon(macmon)
    if not parts:
        parts = [p for p in (cpu_iostat(), mem_vm_stat(), battery_pmset()) if p]
    print(SEP.join(parts))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("")
