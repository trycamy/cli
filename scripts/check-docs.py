#!/usr/bin/env python3
"""Fail if any relative Markdown link in this repository points at a file
that does not exist. External links are not fetched."""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
SKIP = ("http://", "https://", "mailto:", "#")

bad = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d != ".git" and not (dirpath == ROOT + "/npm" and d == "out")]
    for name in filenames:
        if not name.endswith(".md"):
            continue
        path = os.path.join(dirpath, name)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for target in LINK.findall(text):
            if target.startswith(SKIP):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            resolved = os.path.normpath(os.path.join(dirpath, target))
            if not os.path.exists(resolved):
                bad.append(f"{os.path.relpath(path, ROOT)}: {target}")

if bad:
    print("broken relative links:")
    for line in bad:
        print("  " + line)
    sys.exit(1)
print("docs: all relative links resolve")
