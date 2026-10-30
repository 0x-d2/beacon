#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# Stop hook (.claude/settings.json): before an agent reports its work done, make
# sure Beacon's changelog tells about it (ref/release-notes.md). It blocks the stop
# once when the working tree has changes that came after the last edit of
# CHANGELOG.beacon.md and CHANGELOG.beacon.en.md, and lets the agent finish if
# it answers that nothing in them can be noticed (the second stop carries
# `stop_hook_active`, so it never loops).

import datetime
import json
import os
import subprocess
import sys

CHANGELOGS = ("CHANGELOG.beacon.md", "CHANGELOG.beacon.en.md")


def changed_paths(root):
    """Every path git sees as changed or new in the working tree (renames by their new name)."""
    out = subprocess.run(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                         cwd=root, capture_output=True, check=True).stdout.decode("utf-8", "replace")
    entries = out.split("\0")
    paths, index = [], 0
    while index < len(entries):
        entry = entries[index]
        index += 1
        if len(entry) < 4:
            continue
        status, path = entry[:2], entry[3:]
        if "R" in status or "C" in status:
            index += 1  # the old name follows a rename or copy
        paths.append(path)
    return paths


def main():
    payload = json.load(sys.stdin) if not sys.stdin.isatty() else {}
    if payload.get("stop_hook_active"):
        return
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    try:
        paths = changed_paths(root)
    except (OSError, subprocess.CalledProcessError):
        return

    work = [p for p in paths if p not in CHANGELOGS]
    if not work:
        return

    def mtime(path):
        full = os.path.join(root, path)
        return os.path.getmtime(full) if os.path.exists(full) else None

    latest_work = max((t for t in map(mtime, work) if t is not None), default=0)
    logs_current = all(p in paths and (mtime(p) or 0) >= latest_work for p in CHANGELOGS)
    if logs_current:
        return

    today = datetime.date.today().isoformat()
    shown = "\n".join(f"  {p}" for p in work[:12]) + (f"\n  … and {len(work) - 12} more" if len(work) > 12 else "")
    reason = (
        "Beacon's changelog doesn't cover the latest changes in the working tree:\n"
        f"{shown}\n"
        f"Add one plain Turkish line per change someone can notice under `## {today}` (newest first) in "
        "CHANGELOG.beacon.md, and the same line in English at the same place in CHANGELOG.beacon.en.md — "
        "`- **Area:** sentence.`, areas Mac / iPhone / Apple Watch / BeaconKit / Geliştirme (Development); "
        "never in CHANGELOG.md (ref/release-notes.md). If none of these changes can be noticed (a refactor with "
        "no visible effect, tests only), say so in one line and finish."
    )
    print(json.dumps({"decision": "block", "reason": reason}))


if __name__ == "__main__":
    main()
