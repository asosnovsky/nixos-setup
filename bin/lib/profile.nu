const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def valid_profiles [] {
    cd $REPO_ROOT
    nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json err> /dev/null
        | from json
}

export def valid_remote_profiles [] {
    valid_profiles | where {|p| $p | str starts-with "hl-" }
}

export def remote_targets [] {
    valid_remote_profiles | each {|p| $p | str replace "hl-" "" }
}

export def is-valid-profile [name: string, on_remote: bool = false] {
    let pool = if $on_remote { valid_remote_profiles } else { valid_profiles }
    ($pool | where {|p| $p == $name} | length) == 1
}
