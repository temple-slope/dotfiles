#!/usr/bin/env python3
"""Claude Code statusline: Fine-grained progress bar with true color gradient."""
import json
import os
import re
import subprocess
import sys
from datetime import datetime

data = json.load(sys.stdin)

BLOCKS = " \u258f\u258e\u258d\u258c\u258b\u258a\u2589\u2588"
R = "\033[0m"
DIM = "\033[2m"
GREEN = "\033[38;2;120;200;120m"
RED = "\033[38;2;220;90;90m"


def gradient(pct):
    if pct < 50:
        r = int(80 + pct * 1.4)
        return f"\033[38;2;{r};140;90m"
    elif pct < 80:
        r = int(150 + (pct - 50) * 2)
        g = int(140 - (pct - 50) * 1.5)
        return f"\033[38;2;{r};{int(g)};70m"
    else:
        g = int(60 - (pct - 80) * 2.5)
        return f"\033[38;2;220;{max(g, 10)};50m"


def bar(pct, width=10):
    pct = min(max(pct, 0), 100)
    filled = pct * width / 100
    full = int(filled)
    frac = int((filled - full) * 8)
    b = "\u2588" * full
    if full < width:
        b += BLOCKS[frac]
        b += "\u2591" * (width - full - 1)
    return b


def fmt(label, pct):
    p = round(pct)
    return f"{label} {gradient(pct)}{bar(pct)} {p}%{R}"


# --- Line 1: Git | Branch | Model ---
cwd = data.get("cwd", os.getcwd())

git_part = ""
try:
    toplevel = (
        subprocess.check_output(
            ["git", "--no-optional-locks", "-C", cwd, "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
        )
        .decode()
        .strip()
    )
    branch = (
        subprocess.check_output(
            ["git", "--no-optional-locks", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            stderr=subprocess.DEVNULL,
        )
        .decode()
        .strip()
    )
    repo_name = os.path.basename(toplevel)

    porcelain = (
        subprocess.check_output(
            ["git", "--no-optional-locks", "-C", cwd, "status", "--porcelain"],
            stderr=subprocess.DEVNULL,
        )
        .decode()
        .splitlines()
    )
    added = modified = deleted = 0
    for line in porcelain:
        if len(line) < 2:
            continue
        idx, wt = line[0], line[1]
        if idx == "A":
            added += 1
        elif idx in ("M", "R", "C"):
            modified += 1
        elif idx == "D":
            deleted += 1
        if wt == "A":
            added += 1
        elif wt == "M":
            modified += 1
        elif wt == "D":
            deleted += 1

    changes = ""
    if added > 0:
        changes += f" +{added}"
    if modified > 0:
        changes += f" ~{modified}"
    if deleted > 0:
        changes += f" -{deleted}"

    # ahead/behind vs upstream (empty when no upstream / detached / not a repo)
    ahead_behind = ""
    try:
        counts = (
            subprocess.check_output(
                [
                    "git", "--no-optional-locks", "-C", cwd,
                    "rev-list", "--left-right", "--count", "@{upstream}...HEAD",
                ],
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .split()
        )
        behind, ahead = int(counts[0]), int(counts[1])
        if ahead > 0 or behind > 0:
            ab = ""
            if ahead > 0:
                ab += f"\u2191{ahead}"
            if behind > 0:
                ab += f"\u2193{behind}"
            ahead_behind = f" {ab}"
    except Exception:
        ahead_behind = ""

    # Working-tree diff line counts vs HEAD (staged + unstaged)
    diff_lines = ""
    try:
        shortstat = (
            subprocess.check_output(
                ["git", "--no-optional-locks", "-C", cwd, "diff", "HEAD", "--shortstat"],
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )
        ins = re.search(r"(\d+) insertion", shortstat)
        dels = re.search(r"(\d+) deletion", shortstat)
        ins_n = int(ins.group(1)) if ins else 0
        del_n = int(dels.group(1)) if dels else 0
        if ins_n or del_n:
            diff_lines = f" \u270e {GREEN}+{ins_n}{R}/{RED}-{del_n}{R}"
    except Exception:
        diff_lines = ""

    git_part = f"\U0001f419 {repo_name} {DIM}\u2502{R} \U0001f33f {branch}{changes}{ahead_behind}{diff_lines}"
except Exception:
    git_part = ""

model = data.get("model", {}).get("display_name", "")
model_part = f"\U0001f9e0 {model}" if model else ""

line1_parts = [p for p in [git_part, model_part] if p]
line1 = f" {DIM}\u2502{R} ".join(line1_parts) if line1_parts else ""

# --- Line 2: Context | 5h | 7d ---
line2_parts = []

ctx = data.get("context_window", {}).get("used_percentage")
if ctx is not None:
    line2_parts.append(fmt("\U0001f4ad ctx", ctx))

five_data = data.get("rate_limits", {}).get("five_hour", {})
five = five_data.get("used_percentage")
if five is not None:
    seg = fmt("\u23f3 5h", five)
    resets_at = five_data.get("resets_at")
    if resets_at is not None:
        hhmm = datetime.fromtimestamp(resets_at).strftime("%H:%M")
        seg += f" {DIM}\u21bb{hhmm}{R}"
    line2_parts.append(seg)

seven_data = data.get("rate_limits", {}).get("seven_day", {})
week = seven_data.get("used_percentage")
if week is not None:
    seg = fmt("\U0001f4c5 7d", week)
    week_resets_at = seven_data.get("resets_at")
    if week_resets_at is not None:
        dt = datetime.fromtimestamp(week_resets_at)
        seg += f" {DIM}\u21bb{dt.month}/{dt.day}{R}"
    line2_parts.append(seg)

# Session cost (cost.total_cost_usd)
cost = data.get("cost", {})
total_cost = cost.get("total_cost_usd")
if total_cost is not None:
    line2_parts.append(f"{DIM}${total_cost:.2f}{R}")

line2 = f" {DIM}\u2502{R} ".join(line2_parts) if line2_parts else ""

# --- Output ---
if line1:
    print(line1)
if line2:
    print(line2, end="" if not line1 else "\n" if line2 else "")
    if not line1:
        print(end="")
