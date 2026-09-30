export const REPO_ROOT = path self | path dirname | path dirname | path dirname

# Insert a secrets.nix entry for the given secret path if missing.
export def ensure-secret-entry [secret_path: string, recipients: list<string>] {
    let file = "secrets.nix"
    # Read via external cat — `open` type-guessing on .nix files is unreliable.
    let content = (^cat $file)
    if ($content | str contains $secret_path) {
        return
    }
    let entry = $'  "($secret_path)".publicKeys = [ ($recipients | str join " ") ];'
    let lines = ($content | lines)
    # Insert before the final top-level closing brace.
    let closing = ($lines | enumerate | where item == "}" | last)
    if $closing == null {
        error make {msg: $"Could not find the final '}' in ($file) — refusing to edit"}
    }
    let new_lines = ($lines | insert $closing.index $entry)
    ($new_lines | str join "\n") + "\n" | save -f $file
    print $"📝 Registered ($secret_path) in secrets.nix — review with git diff"
}

# Render a Gitea-style Go template to a standalone HTML file for local preview.
# Swaps the base/head + base/footer includes for a minimal shell and drops any
# remaining {{ ... }} directives so the page opens in a plain browser.
export def render-html-tpl [src: string, out: string] {
    let head = '<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Template preview</title><style>html,body{margin:0;background:#f6f8fa;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:#1f2328;}</style></head><body>'
    let foot = '</body></html>'
    # Read via external cat — `open` is aliased to xdg-open in some Nu configs.
    ^cat $src
    | str replace -a '{{template "base/head" .}}' $head
    | str replace -a '{{template "base/footer" .}}' $foot
    | str replace -a -r '\{\{[^}]*\}\}' ''
    | save -f $out
}
