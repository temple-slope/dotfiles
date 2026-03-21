#!/usr/bin/env python3
"""Claude Code statusline: Fine-grained progress bar with true color gradient."""
import json
import os
import subprocess
import sys

data = json.load(sys.stdin)

BLOCKS = " \u258f\u258e\u258d\u258c\u258b\u258a\u2589\u2588"
R = "\033[0m"
DIM = "\033[2m"


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

    git_part = f"\U0001f419 {repo_name} {DIM}\u2502{R} \U0001f33f {branch}{changes}"
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

five = data.get("rate_limits", {}).get("five_hour", {}).get("used_percentage")
if five is not None:
    line2_parts.append(fmt("\u23f3 5h", five))

week = data.get("rate_limits", {}).get("seven_day", {}).get("used_percentage")
if week is not None:
    line2_parts.append(fmt("\U0001f4c5 7d", week))

line2 = f" {DIM}\u2502{R} ".join(line2_parts) if line2_parts else ""

# --- Output ---
if line1:
    print(line1)
if line2:
    print(line2, end="" if not line1 else "\n" if line2 else "")
    if not line1:
        print(end="")
