"""Copy the spindumps XCTest attached to timed-out tests out of the exported result bundle, one file per stop.

    python3 ci/spindumps.py <out dir> <timed_out.txt> <export dir> [<export dir> ...]

Each export dir is what `xcresulttool export attachments` or `export diagnostics` wrote. A file is a spindump when its
text holds a `Call graph` (what XCTest attaches when a test runs past its time allowance). It belongs to the stop whose
test name (`test_005_frozen`) appears in its manifest entry or in its path; with one timed-out stop and one unassigned
spindump the two belong together. Writes `<out dir>/<stop id>.txt` and `<out dir>/index.txt`. No network.
"""
import json
import re
import shutil
import sys
from pathlib import Path

METHOD = re.compile(r"test_\d+_([a-z0-9_]+)")
IMAGES = {".png", ".jpg", ".jpeg", ".heic", ".mp4", ".mov"}


def is_spindump(path):
    try:
        with open(path, "rb") as f:
            head = f.read(200_000).decode("utf-8", errors="replace")
    except OSError:
        return False
    return "Call graph" in head


def stop_of(text):
    m = METHOD.search(text or "")
    return m.group(1).replace("_", "-") if m else None


def manifest_owners(folder):
    """{exported file name: stop id} from the `manifest.json` that `export attachments` writes, whatever its nesting."""
    owners = {}
    try:
        data = json.loads((folder / "manifest.json").read_text())
    except (OSError, ValueError):
        return owners

    def walk(node, test=""):
        if isinstance(node, dict):
            test = str(node.get("testIdentifier") or node.get("testIdentifierURL") or node.get("testName") or test)
            for key in ("exportedFileName", "filename", "fileName"):
                if isinstance(node.get(key), str):
                    owners[node[key]] = stop_of(test)
            for value in node.values():
                walk(value, test)
        elif isinstance(node, list):
            for value in node:
                walk(value, test)

    walk(data)
    return owners


def collect(out, timed_out, folders):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    found = {}
    loose = []
    for folder in map(Path, folders):
        owners = manifest_owners(folder)
        for path in sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() not in IMAGES
                           and p.name != "manifest.json"):
            if not is_spindump(path):
                continue
            stop = owners.get(path.name) or stop_of(str(path.relative_to(folder)))
            if stop in timed_out:
                found.setdefault(stop, []).append(path)
            else:
                loose.append(path)
    if len(timed_out) == 1 and loose and not found:
        found[timed_out[0]], loose = loose, []
    index = []
    for stop, paths in sorted(found.items()):
        for n, path in enumerate(paths):
            name = f"{stop}.txt" if n == 0 else f"{stop}-{n + 1}.txt"
            shutil.copyfile(path, out / name)
            index.append(f"{stop} {name}")
    for n, path in enumerate(loose, 1):
        shutil.copyfile(path, out / f"unassigned-{n}.txt")
        index.append(f"? unassigned-{n}.txt")
    (out / "index.txt").write_text("\n".join(index) + ("\n" if index else ""))
    return index


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    ids = Path(sys.argv[2]).read_text().split() if Path(sys.argv[2]).is_file() else []
    print("\n".join(collect(sys.argv[1], ids, sys.argv[3:])))
