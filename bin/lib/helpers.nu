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
