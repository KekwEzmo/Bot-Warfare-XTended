#!/usr/bin/env python3
"""
Generates ci/release/xtended.cfg from the DVARs table in README.md, so the settings file
always matches the documentation.

Usage: python ci/gen_cfg.py
"""

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README = os.path.join(ROOT, "README.md")
OUT_PATH = os.path.join(ROOT, "ci", "release", "xtended.cfg")

HEADER = """// Bot Warfare XTended settings
//
// Change the values you want, then type  exec xtended.cfg  in the console,
// or add  +exec xtended.cfg  to your Plutonium launch options so it runs every time.
// On a dedicated server, copy the lines you want into your server config.
//
// Every setting is "set <name> <value>". Lines starting with // are comments.
// Tip: bots_real_preset applies a whole group of settings at once (see the XTended section).
"""


def clean(text):
    """Turns a README table description into a plain one-line comment."""
    text = re.sub(r"<li>", "; ", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("`", "")
    text = re.sub(r"\s+", " ", text).strip(" ;")
    return text.replace(".;", ";").replace(":;", ":")


def rows():
    """Yields (name, description, default) from the README dvar table."""
    in_table = False

    for line in open(README, encoding="latin1"):
        line = line.rstrip("\r\n")

        if line.startswith("| Dvar"):
            in_table = True
            continue

        if not in_table:
            continue

        if not line.startswith("|"):
            break

        cells = [c.strip() for c in line.strip("|").split("|")]

        if len(cells) < 3 or cells[0].startswith("---"):
            continue

        yield cells[0], clean(" | ".join(cells[1:-1])), cells[-1]


def main():
    out = [HEADER]
    section = None

    for name, desc, default in rows():
        wanted = "XTended" if name.startswith("bots_real_") else "Bot Warfare"

        if wanted != section:
            section = wanted
            out.append("\n// ================= %s =================\n" % section)

        value = default if default else '""'
        out.append("// %s\nset %s %s\n" % (desc, name, value))

    with open(OUT_PATH, "w", newline="\r\n") as f:
        f.write("\n".join(out))

    print("wrote %s" % os.path.relpath(OUT_PATH, ROOT))


if __name__ == "__main__":
    main()
