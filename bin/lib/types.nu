const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def hm-actions [] {
    ["switch", "build"]
}

export def os-actions [] {
    [
        "test"
        "dry-activate"
        "run"
        "switch"
        "build"
        "boot"
    ]
}

export def image-targets [] {
    ["iso", "pi1", "pi2"]
}

export def secret-names [] {
    cd $REPO_ROOT
    glob secrets/*.age | each {|f| $f | path basename | str replace ".age" "" }
}

export def updatable-pkgs [] {
    cd $REPO_ROOT
    glob "pkgs/*/update.sh"
    | each {|f| $f | path dirname | path basename }
}

# Gitea HTML templates, for `skyg render html-tpl` tab-completion.
export def html-tpl-files [] {
    cd $REPO_ROOT
    glob "**/*.tmpl"
    | each {|f| $f | path relative-to $REPO_ROOT }
    | sort
}

# Flake input names from flake.nix
export def flake-inputs [] {
    cd $REPO_ROOT
    open flake.nix
    | lines
    | where {|l| $l =~ '^\s+\w+\.url\s*=' }
    | each {|l| $l | str trim | split row "." | first }
    | uniq
}

# OpenWrt router names from openwrt-routers/*.nix
export def router-names [] {
    cd $REPO_ROOT
    glob openwrt-routers/*.nix | each {|f| $f | path basename | str replace ".nix" "" }
}

# CA recipient names from secrets.nix
export def ca-recipients [] {
    cd $REPO_ROOT
    ^cat secrets.nix | parse --regex '(\w+) = "ssh-' | get capture0
}
