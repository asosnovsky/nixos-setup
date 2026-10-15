use types.nu *
use profile.nu *
use helpers.nu *
export use remote.nu *
export use os.nu *
export use secrets.nu *
export use ca.nu *
export use pkgs.nu *
export use flake.nu *
export use build.nu *
export use render.nu *
export use hm.nu *

export def skyg [] {
    print $REPO_ROOT
    let subcmds = (help commands |
    		where name starts-with "skyg " |
    		each {|c| $c.name | split row " " | get 1 } |
    		uniq | str join ', ')
    print $"Subcommands: ($subcmds)"
    print "Run: skyg <subcommand> --help"
}

export def "skyg profiles" [only_remote: bool = false] {
    if $only_remote {
        valid_remote_profiles | print
    } else {
        valid_profiles | print
    }
}

# --- Deprecated aliases (backward compatibility) ---

export def "skyg decrypt" [secret: string@secret-names] {
    print $"(ansi yellow)Deprecated: use `skyg secrets show` instead(ansi reset)"
    skyg secrets show $secret
}

export def "skyg encrypt" [
    secret: string@secret-names,
    source?: string,
    --yaml
] {
    print $"(ansi yellow)Deprecated: use `skyg secrets edit` instead(ansi reset)"
    skyg secrets edit $secret $source --yaml=$yaml
}

export def "skyg compare-secret" [secret: string@secret-names] {
    print $"(ansi yellow)Deprecated: use `skyg secrets compare` instead(ansi reset)"
    skyg secrets compare $secret
}

export def "skyg secrets" [] {
    print $"(ansi yellow)Deprecated: use `skyg secrets list` instead(ansi reset)"
    skyg secrets list
}

export def "skyg rollback" [] {
    print $"(ansi yellow)Deprecated: use `skyg os rollback` instead(ansi reset)"
    skyg os rollback
}

export def "skyg update" [input_name?: string] {
    print $"(ansi yellow)Deprecated: use `skyg flake update` instead(ansi reset)"
    skyg flake update $input_name
}

export def "skyg check" [] {
    print $"(ansi yellow)Deprecated: use `skyg flake check` instead(ansi reset)"
    skyg flake check
}

export def "skyg check-flake-versions" [] {
    print $"(ansi yellow)Deprecated: use `skyg flake check-versions` instead(ansi reset)"
    skyg flake check-versions
}

export def "skyg build-image" [target: string] {
    print $"(ansi yellow)Deprecated: use `skyg build image` instead(ansi reset)"
    skyg build image $target
}

export def "skyg openwrt" [
    router?: string,
    --dry-run
] {
    print $"(ansi yellow)Deprecated: use `skyg build openwrt` instead(ansi reset)"
    skyg build openwrt $router --dry-run=$dry_run
}
