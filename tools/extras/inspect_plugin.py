#!/usr/bin/env python3
"""Read-only plugin summary via the bethkit Python library (optional; not pinned in requirements.txt).

Install bethkit yourself into the kit venv if you want this, after reviewing its source and license.
Usage: inspect_plugin.py <copy-of-plugin.esp>   (never point at a live file being edited)
"""
import sys
from pathlib import Path
from bethkit import Plugin, Game

def main():
    if len(sys.argv) < 2:
        print("usage: inspect_plugin.py <plugin.esp|esm|esl>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    with Plugin.open(path, Game.SKYRIM_SE) as plugin:
        print(f"path={path}")
        print(f"kind={plugin.kind}")
        print(f"masters={list(plugin.masters)}")
        records = []
        for group in plugin:
            for child in group:
                fid = getattr(child, "form_id", None)
                if fid is None:
                    continue
                sig = getattr(child, "signature", None)
                if isinstance(sig, (bytes, bytearray)):
                    sig = sig.decode("ascii", "replace")
                eid = getattr(child, "editor_id", None)
                records.append((sig, fid, eid))
        print(f"records={len(records)}")
        for sig, fid, eid in records:
            print(f"  {sig}\t0x{fid:08X}\t{eid}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
