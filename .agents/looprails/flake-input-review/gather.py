"""Collect bounded upstream samples and local references for the reviewer."""
import http.client
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.error import URLError
from urllib.request import Request, urlopen


def github_repo(node):
    locked = (node or {}).get("locked", {})
    if locked.get("type") == "github":
        slug = f"{locked['owner']}/{locked['repo']}"
    else:
        match = re.match(r"https://api\.flakehub\.com/f/pinned/(NixOS/nixpkgs|DeterminateSystems/determinate)/",
                         locked.get("url", ""), re.I)
        if not match:
            return None
        slug = match[1]
    return slug if re.fullmatch(r"[\w.-]+/[\w.-]+", slug) else None


def github(endpoint, gaps):
    url = f"https://api.github.com/repos/{endpoint}"
    try:
        with urlopen(Request(url, headers={"User-Agent": "flake-input-review"}), timeout=15) as response:
            return json.load(response)
    except (OSError, URLError, http.client.HTTPException, ValueError) as error:
        gaps.append(f"{url}: {error}")
        return None


def collect(preview):
    name = preview["name"]
    refs = subprocess.run(["rg", "-n", "--fixed-strings", "--glob", "*.nix", "--", name,
                           "flake.nix", "hosts", "modules", "pkgs"], capture_output=True, text=True)
    if refs.returncode not in (0, 1):
        raise RuntimeError(refs.stderr)
    data = {"references": refs.stdout.splitlines(), "comparisons": {},
            "commits": [], "releases": [], "open_issues": [], "gaps": []}
    for path, (old, new) in preview["changes"].items():
        repo = github_repo(new)
        first, last = [(node or {}).get("locked", {}).get("rev", "") for node in (old, new)]
        if repo and repo == github_repo(old) and all(re.fullmatch("[a-fA-F0-9]{40}", r) for r in (first, last)):
            data["comparisons"][path] = f"https://github.com/{repo}/compare/{first}...{last}"

    repo = github_repo(preview.get("candidate"))
    if not repo:
        data["gaps"].append("No public GitHub collector for this source. Check its upstream directly.")
        return data

    gaps = data["gaps"]
    compare = data["comparisons"].get(name)
    if compare:
        payload = github(f"{repo}/compare/{compare.rsplit('/', 1)[1]}?per_page=60", gaps)
        if payload:
            data["comparison_status"] = payload["status"]
            data["total_commits"] = payload["total_commits"]
            data["commits"] = [{"subject": c["commit"]["message"].splitlines()[0], "url": c["html_url"]}
                               for c in payload["commits"]]
            data["changed_files_sample"] = [f["filename"] for f in payload.get("files", [])]
            if payload["total_commits"] > len(data["commits"]):
                gaps.append(f"Sampled {len(data['commits'])} of {payload['total_commits']} commits.")
    else:
        gaps.append("No direct revision comparison available for the selected input.")
    releases = github(f"{repo}/releases?per_page=8", gaps) or []
    data["releases"] = [{"tag": r["tag_name"], "url": r["html_url"], "notes": (r["body"] or "")[:4000]}
                        for r in releases]
    issues = github(f"{repo}/issues?state=open&sort=updated&per_page=50", gaps) or []
    data["open_issues"] = [{"title": i["title"], "url": i["html_url"]}
                           for i in issues if "pull_request" not in i]
    gaps.append("Release notes and recently updated open issues are bounded samples, unverified for this range.")
    return data


if __name__ == "__main__":
    preview_path = Path(sys.argv[1])
    target = preview_path.with_name("evidence.json")
    target.write_text(json.dumps(collect(json.loads(preview_path.read_text())), indent=2))
    Path(os.environ["LOOPRAIL_OUTPUTS"]).write_text(json.dumps({"evidence": str(target)}))
