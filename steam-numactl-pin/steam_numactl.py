#!/usr/bin/env python3
"""Prefix Steam launch options for INSTALLED games with numactl pinning.

Dry run by default. Use --apply to write, --remove to undo.
Steam must be fully closed when using --apply.

Setup (Mint/Ubuntu):  python3 -m venv ~/.venvs/svdf && ~/.venvs/svdf/bin/pip install vdf
Run:                  ~/.venvs/svdf/bin/python steam_numactl.py [--apply] [--remove]
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys
import time

try:
    import vdf
except ImportError:
    sys.exit("Missing dependency 'vdf'. See setup line at the top of this script.")

PREFIX = "numactl --cpunodebind=0 --membind=0"
SKIP = ("proton", "steam linux runtime", "steamworks common")


def ci(d, key, create=False):
    """Case-insensitive dict lookup (Steam's key casing varies)."""
    for k in d:
        if k.lower() == key.lower():
            return d[k]
    if create:
        d[key] = {}
        return d[key]
    return None


def installed_apps(steam):
    libs = {steam}
    lf = os.path.join(steam, "steamapps", "libraryfolders.vdf")
    if os.path.exists(lf):
        with open(lf, encoding="utf-8", errors="replace") as f:
            data = vdf.load(f)
        for v in (ci(data, "libraryfolders") or {}).values():
            if isinstance(v, dict) and "path" in v:
                libs.add(v["path"])
            elif isinstance(v, str) and v.startswith("/"):  # old format
                libs.add(v)
    apps = {}
    for lib in libs:
        for mf in glob.glob(os.path.join(lib, "steamapps", "appmanifest_*.acf")):
            try:
                with open(mf, encoding="utf-8", errors="replace") as f:
                    st = ci(vdf.load(f), "AppState")
                apps[st["appid"]] = st.get("name", "?")
            except Exception:
                continue
    return apps


def transform(cur, remove):
    if remove:
        new = cur.replace(PREFIX + " ", "")
        return "" if new.strip() == "%command%" else new
    if "numactl" in cur:
        return cur
    if "%command%" in cur:
        return cur.replace("%command%", PREFIX + " %command%", 1)
    return f"{PREFIX} %command% {cur}".strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--steam", default="~/.local/share/Steam", help="Steam root dir")
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    ap.add_argument("--remove", action="store_true", help="undo: strip the numactl prefix")
    args = ap.parse_args()

    steam = os.path.realpath(os.path.expanduser(args.steam))
    if args.apply and subprocess.run(["pgrep", "-x", "steam"], capture_output=True).returncode == 0:
        sys.exit("Steam is running. Fully exit it (Steam > Exit) and retry.")

    apps = installed_apps(steam)
    configs = glob.glob(os.path.join(steam, "userdata", "*", "config", "localconfig.vdf"))
    if not configs:
        sys.exit(f"No localconfig.vdf found under {steam}/userdata")
    print(f"{len(apps)} installed apps found.")

    for cfg in configs:
        with open(cfg, encoding="utf-8", errors="replace") as f:
            data = vdf.load(f)
        node = ci(data, "UserLocalConfigStore", create=True)
        for key in ("Software", "Valve", "Steam", "apps"):
            node = ci(node, key, create=True)

        changed = 0
        for appid, name in sorted(apps.items(), key=lambda x: x[1].lower()):
            if any(s in name.lower() for s in SKIP):
                continue
            entry = ci(node, appid)
            cur = entry.get("LaunchOptions", "") if entry else ""
            new = transform(cur, args.remove)
            if new == cur:
                continue
            changed += 1
            print(f"  {name} ({appid}): {cur!r} -> {new!r}")
            if new == "":
                entry.pop("LaunchOptions", None)
            else:
                node.setdefault(appid, {})["LaunchOptions"] = new

        print(f"{cfg}: {changed} change(s)")
        if args.apply and changed:
            shutil.copy2(cfg, f"{cfg}.bak-{int(time.time())}")
            tmp = cfg + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                vdf.dump(data, f, pretty=True)
            os.replace(tmp, cfg)
            print("  written (backup saved alongside)")

    if not args.apply:
        print("\nDry run only. Re-run with --apply (Steam closed) to write.")


if __name__ == "__main__":
    main()
