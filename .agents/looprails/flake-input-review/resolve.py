"""Resolve only the requested input. Write artifacts in Looprail's per-run directory."""
import difflib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def lock_paths(lock):
    """Index by input path so Nix renumbering nodes does not invent bumps."""
    paths = {}

    def visit(parent, node_id):
        for name, edge in lock["nodes"][node_id].get("inputs", {}).items():
            path = f"{parent}/{name}" if parent else name
            if isinstance(edge, list):
                paths[path] = {"follows": edge}
            else:
                node = lock["nodes"][edge]
                paths[path] = {k: v for k, v in node.items() if k != "inputs"}
                visit(path, edge)

    visit("", lock["root"])
    return paths


def main(requested):
    run = Path(os.environ["LOOPRAIL_CURRENT_RUN_DIR"])
    with tempfile.TemporaryDirectory() as tmp:
        snapshot = Path(tmp)
        shutil.copyfile("flake.nix", snapshot / "flake.nix")
        lock = snapshot / "flake.lock"
        shutil.copyfile("flake.lock", lock)
        names = json.loads(subprocess.check_output([
            "nix-instantiate", "--eval", "--strict", "--json", "--expr",
            "builtins.attrNames (import ./flake.nix).inputs",
        ], cwd=snapshot))
        name = "nixpkgs" if requested == "nixpkgs-stable" and requested not in names else requested
        if name not in names:
            sys.exit("Choose a declared input: " + ", ".join(names))
        before = lock.read_text()
        old = lock_paths(json.loads(before))
        result = subprocess.run(["nix", "flake", "update", name, "--flake", f"path:{tmp}"],
                                cwd=snapshot, capture_output=True, text=True)
        preview = {"name": name, "requested": requested, "current": old.get(name),
                   "changes": {}, "error": "", "diff": ""}
        if result.returncode:
            preview["error"] = result.stderr.strip()[-3000:] or f"Nix exited {result.returncode}"
        else:
            after = lock.read_text()
            new = lock_paths(json.loads(after))
            preview["candidate"] = new.get(name)
            for path in sorted(old.keys() | new.keys()):
                if old.get(path) != new.get(path):
                    preview["changes"][path] = [old.get(path), new.get(path)]
            preview["diff"] = "".join(difflib.unified_diff(
                before.splitlines(True), after.splitlines(True), "current/flake.lock", "candidate/flake.lock"))
    target = run / "preview.json"
    target.write_text(json.dumps(preview, indent=2))
    Path(os.environ["LOOPRAIL_OUTPUTS"]).write_text(json.dumps(
        {"preview": str(target), "changed": bool(preview["changes"])}))


if __name__ == "__main__":
    main(sys.argv[1])
