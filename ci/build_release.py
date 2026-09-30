#!/usr/bin/env python3
"""
Builds the Bot Warfare XTended release zip, laid out like the official Bot Warfare release:

    out/BotWarfareXTended-1.0.zip
        install.bat        copies the iwd into %LOCALAPPDATA%\\Plutonium\\storage\\iw5\\
        README.txt
        bots.txt           bot names, copied only if you don't have one yet
        xtended.cfg        every setting with comments, copied only if you don't have one yet
        z_svr_bots.iwd     the mod's maps/ and scripts/ .gsc files

Usage: python ci/build_release.py
"""

import os
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "out")
IWD_NAME = "z_svr_bots.iwd"
ZIP_NAME = "BotWarfareXTended-1.0.zip"


def gsc_files():
    """Returns the repo-relative paths of every .gsc under maps/ and scripts/, sorted."""
    files = []

    for top in ("maps", "scripts"):
        for dirpath, _, filenames in os.walk(os.path.join(ROOT, top)):
            for name in filenames:
                if name.endswith(".gsc"):
                    files.append(os.path.relpath(os.path.join(dirpath, name), ROOT).replace(os.sep, "/"))

    return sorted(files)


def dir_entries(files):
    """Returns the folder entries for the files, like the official iwd has."""
    dirs = set()

    for f in files:
        parts = f.split("/")[:-1]

        for i in range(1, len(parts) + 1):
            dirs.add("/".join(parts[:i]) + "/")

    return sorted(dirs)


def main():
    files = gsc_files()

    if "scripts/mp/bots.gsc" not in files or "maps/mp/bots/_bot.gsc" not in files:
        sys.exit("error: run this from a Bot Warfare checkout (missing entry scripts)")

    os.makedirs(OUT_DIR, exist_ok=True)
    iwd_path = os.path.join(OUT_DIR, IWD_NAME)
    zip_path = os.path.join(OUT_DIR, ZIP_NAME)

    with zipfile.ZipFile(iwd_path, "w", zipfile.ZIP_DEFLATED) as iwd:
        for d in dir_entries(files):
            iwd.writestr(zipfile.ZipInfo(d), b"")

        for f in files:
            iwd.write(os.path.join(ROOT, f), f)

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as out:
        out.write(os.path.join(ROOT, "ci", "release", "install.bat"), "install.bat")
        out.write(os.path.join(ROOT, "ci", "release", "README.txt"), "README.txt")

        # bot names, generated once by ci/gen_bot_names.py
        names = os.path.join(ROOT, "ci", "release", "bots.txt")

        if not os.path.exists(names):
            subprocess.check_call([sys.executable, os.path.join(ROOT, "ci", "gen_bot_names.py")])

        out.write(names, "bots.txt")

        # settings file, regenerated from the README's dvar table so it always matches
        subprocess.check_call([sys.executable, os.path.join(ROOT, "ci", "gen_cfg.py")])
        out.write(os.path.join(ROOT, "ci", "release", "xtended.cfg"), "xtended.cfg")
        out.write(iwd_path, IWD_NAME)

    print("packed %d scripts into %s" % (len(files), IWD_NAME))
    print("wrote %s" % os.path.relpath(zip_path, ROOT))


if __name__ == "__main__":
    main()
