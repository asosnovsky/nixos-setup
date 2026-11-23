"""Produce a standalone HTML report from the preview and typed agent outputs."""
import json
import os
import re
import sys
from datetime import datetime, timezone
from html import escape
from pathlib import Path
from urllib.parse import urlsplit


def linked(text):
    chunks = re.split(r"(https?://[^\s<>\x22\x27]+)", text)
    for i, chunk in enumerate(chunks):
        if i % 2:
            url = chunk.rstrip(".,;)")
            chunks[i] = f'<a href="{escape(url)}">{escape(url)}</a>' + escape(chunk[len(url):])
        else:
            chunks[i] = escape(chunk)
    return "".join(chunks)


def revision(node):
    if node is None:
        return "Absent"
    if "follows" in node:
        return "Follows " + "/".join(node["follows"])
    lock = node["locked"]
    return lock.get("rev") or lock.get("narHash") or json.dumps(lock, sort_keys=True)


def render(preview, assessment):
    name = escape(preview["name"])
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    changes = preview["changes"]
    body = [f"<header><h1>{name} update review</h1><p>{now}</p></header>"]
    if preview["error"]:
        body.append("<h2>Candidate unresolved</h2><p>Switch in place and boot after reboot both have "
                    "unknown risk. Nix could not resolve this candidate.</p>"
                    f"<pre>{escape(preview['error'])}</pre>")
    elif changes:
        summary, switch, boot, raw_issues, coverage = assessment
        for title, value in [("Switch in place", switch), ("Boot and reboot", boot),
                             ("Changes and affected hosts", summary)]:
            body.append(f"<section><h2>{title}</h2><p>{linked(value)}</p></section>")
        issues = json.loads(raw_issues)
        categories = ("Fixed", "Reported regression", "Potential regression")
        if not isinstance(issues, list):
            raise ValueError("Expected a JSON array of issues")
        for issue in issues:
            if issue["kind"] not in categories or not issue["detail"].strip():
                raise ValueError("Expected a categorized issue with an explanation")
        for category in categories:
            entries = []
            for issue in issues:
                if issue["kind"] == category:
                    source = issue["source"]
                    location = urlsplit(source)
                    if location.scheme not in ("http", "https") or not location.netloc:
                        raise ValueError(f"Expected upstream URL for {category}")
                    entries.append(f'<li>{escape(issue["detail"])} <a href="{escape(source)}">Source</a></li>')
            body.append(f"<h2>{category}</h2>" + ("<ul>" + "".join(entries) + "</ul>" if entries
                        else "<p>None identified in the evidence reviewed.</p>"))
        body.append(f"<h2>Coverage and pre-deployment checks</h2><p>{linked(coverage)}</p>")
    else:
        body.append("<h2>No bump</h2><p>The declared input resolved to the same lock graph. "
                    "This preview introduces no change to switch or boot.</p>")
    body.append(f"<h2>Selected input</h2><p>Current <code>{escape(revision(preview['current']))}</code></p>")
    if "candidate" in preview:
        body.append(f"<p>Candidate <code>{escape(revision(preview['candidate']))}</code></p>")
    if changes:
        body.append("<h2>Changed input paths</h2><table><tr><th>Input path</th><th>Current</th><th>Candidate</th></tr>")
        for path, (old, new) in changes.items():
            body.append(f"<tr><td>{escape(path)}</td><td>{escape(revision(old))}</td>"
                        f"<td>{escape(revision(new))}</td></tr>")
        body.append("</table>")
    if preview["diff"]:
        body.append(f"<details><summary>Full lockfile diff</summary><pre>{escape(preview['diff'])}</pre></details>")
    body.append("<footer>Source review only. Build, activation and reboot were not tested.</footer>")
    return f"""<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>{name} update review</title>
<style>
:root{{color-scheme:light dark;font:1rem/1.55 system-ui,sans-serif}}
body{{max-width:68rem;margin:auto;padding:2rem;overflow-wrap:anywhere}}
header,section{{border-bottom:1px solid #8886}}h2{{margin-bottom:.35rem;font-size:1.25rem}}
p,pre{{white-space:pre-wrap}}table{{width:100%;border-collapse:collapse;font-size:.9rem}}
td,th{{text-align:left;padding:.45rem;border-bottom:1px solid #8886}}
summary{{cursor:pointer}}details,footer{{margin-top:2rem}}
</style><main>{''.join(body)}</main></html>"""


if __name__ == "__main__":
    preview_path = Path(sys.argv[1])
    target = preview_path.with_name("flake-input-review.html")
    target.write_text(render(json.loads(preview_path.read_text()), sys.argv[2:]))
    Path(os.environ["LOOPRAIL_OUTPUTS"]).write_text(json.dumps({"report": str(target)}))
    print(target)
