"""Copy the spindumps XCTest attached to timed-out tests out of the result bundle, one file per stop.

    python3 ci/spindumps.py <out dir> <timed_out.txt> <dir> [<dir> ...]

Each `<dir>` is an export of `xcresulttool` (`export attachments`, `export diagnostics`) or the `.xcresult` bundle itself
(where the spindump is a zstd-compressed blob under `Data/`, or a loose file under `Staging/`). A file is a spindump when
it opens with the report XCTest requested from testmanagerd (`Reason: Requested by testmanagerd [..] - XCTest Diagnostics`)
or is a `Data Source:` / `Report Version:` process report. It belongs to the stop whose test name (`test_005_frozen`)
appears in its manifest entry or in its path; otherwise the unassigned spindumps are paired with the timed-out stops in
time order when the counts agree. Writes `<out dir>/<stop id>.txt` (the whole report, every process of the simulator),
`<out dir>/<stop id>.app.txt` (only the processes of apps installed on the simulator: the app under test, its threads and
frames) and `<out dir>/index.txt`. No network.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

METHOD = re.compile(r"test_\d+_([a-z0-9_]+)")
IMAGES = {".png", ".jpg", ".jpeg", ".heic", ".mp4", ".mov", ".zip"}
TIME = re.compile(r"^Date/Time:\s+(\S+ \S+)", re.M)
ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"


def zstd(path):
    """The decompressed bytes of one blob of a result bundle, or None (not zstd, or no way to decompress it here)."""
    try:
        from compression import zstd as z  # Python 3.14
        return z.decompress(Path(path).read_bytes())
    except Exception:
        pass
    try:
        r = subprocess.run(["zstd", "-dc", str(path)], capture_output=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None
    return r.stdout if r.returncode == 0 else None


def read_text(path, decompress=zstd):
    try:
        with open(path, "rb") as f:
            raw = f.read(60_000_000)
    except OSError:
        return ""
    if raw[:4] == ZSTD_MAGIC:
        raw = decompress(path) or b""
    if b"\0" in raw[:2000]:
        return ""
    return raw.decode("utf-8", errors="replace")


def is_spindump(text):
    head = text[:8000]
    return "XCTest Diagnostics" in head or ("Data Source:" in head and "Report Version:" in head)


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


def app_processes(text):
    """The `Process:` sections of apps installed on the simulator (not the test runner, not system daemons)."""
    keep = []
    for section in re.split(r"(?m)^(?=Process:)", text):
        top = section[:1500]
        if section.startswith("Process:") and "/Containers/Bundle/Application/" in top \
                and not re.search(r"(?m)^Identifier:\s+\S*\.xctrunner\s*$", top):
            keep.append(section)
    return "".join(keep)


def collect(out, timed_out, folders):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    found, loose, seen = {}, [], set()
    for folder in map(Path, folders):
        if not folder.is_dir():
            continue
        owners = manifest_owners(folder)
        for path in sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() not in IMAGES
                           and p.name != "manifest.json"):
            text = read_text(path)
            if not is_spindump(text):
                continue
            when = TIME.search(text)
            key = (when.group(1) if when else "", len(text))
            if key in seen:  # the same report exported twice
                continue
            seen.add(key)
            stop = owners.get(path.name) or stop_of(str(path.relative_to(folder)))
            (found.setdefault(stop, []) if stop in timed_out else loose).append((key, text))
    missing = [s for s in timed_out if s not in found]
    loose.sort(key=lambda item: item[0])
    if loose and len(loose) == len(missing):
        for stop, item in zip(missing, loose):
            found[stop] = [item]
        loose = []
    index = []
    for stop, items in sorted(found.items()):
        for n, (_, text) in enumerate(sorted(items, key=lambda item: item[0])):
            name = f"{stop}.txt" if n == 0 else f"{stop}-{n + 1}.txt"
            (out / name).write_text(text)
            index.append(f"{stop} {name}")
            app = app_processes(text)
            if app:
                (out / name.replace(".txt", ".app.txt")).write_text(app)
    for n, (_, text) in enumerate(loose, 1):
        (out / f"unassigned-{n}.txt").write_text(text)
        index.append(f"? unassigned-{n}.txt")
    (out / "index.txt").write_text("\n".join(index) + ("\n" if index else ""))
    return index


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    ids = Path(sys.argv[2]).read_text().split() if Path(sys.argv[2]).is_file() else []
    print("\n".join(collect(sys.argv[1], ids, sys.argv[3:])))
