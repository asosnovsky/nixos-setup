use types.nu *
use profile.nu *

const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def skyg [] {
    print $REPO_ROOT
    let subcmds = (help commands |
    		where name starts-with "skyg " |
    		each { |c| $c.name | split row " " | get 1 } |
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

export def "skyg check" [] {
	nix flake check --no-build
}

# rollback configuration
export def "skyg rollback" [] {
    sudo nixos-rebuild switch --rollback
}

# update some flakes
export def "skyg update" [input_name: string = ""] {
    cd $REPO_ROOT
    if $input_name == "" {
        print "Updating all flakes..."
        nix flake update | print
    } else {
        print $"Updating flake: ($input_name)"
        nix flake update $input_name | print
    }
    git diff flake.lock | print
}


# Build local os
export def "skyg os" [
	cmd: string@remote-cmds,
	--build-host: string@remote_targets = ""
] {
    cd $REPO_ROOT
    mut runcmd = $"nh os ($cmd)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    $runcmd | print
    bash -c $runcmd
}

# Deploy to remote machine
export def "skyg remote" [
    cmd: string@remote-cmds,
    target: string@remote_targets = "",
    --build-host: string@remote_targets = "", # Optional remote builder host (e.g. builder.lab.internal)
] {
    cd $REPO_ROOT
    mut target_host = $"root@($target).lab.internal"
    mut profile = $"hl-($target)"
    if not (is-valid-profile $profile true) {
        print $"Invalid Remote Profile '(ansi green_bold)($target)(ansi reset)', please select one of:"
        return (remote_targets)
    }
    $"Using [(ansi green_bold)($profile)(ansi reset)]" | print
    $"($cmd) on ($target_host) with ($profile)" | print
    mut runcmd = $"nh os ($cmd) --target-host ($target_host) --ask .#($profile)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    $runcmd | print
    bash -c $runcmd
}

# Deploy OpenWrt router configuration
export def "skyg openwrt" [router: string = "glmain"] {
    cd $REPO_ROOT
    bash -c $"age -d -i ~/.ssh/id_ed25519 secrets/($router).json.age | nix run .#openwrt-($router)"
}

# Build ISO image
export def "skyg build-iso" [] {
    cd $REPO_ROOT
    nix build .#nixosConfigurations.iso.config.system.build.isoImage
    ls -l result/iso
}

# Home Manager operations
export def "skyg hm" [action: string@hm-actions, profile: string = "ari"] {
    cd $REPO_ROOT
    $"Running home-manager ($action) for profile ($profile)" | print
    home-manager $action --flake $".#($profile)"
}

# List all secret names
export def "skyg secrets" [] {
    secret-names
}

# Decrypt a secret from secrets/ folder
export def "skyg decrypt" [secret: string@secret-names] {
    cd $REPO_ROOT
    let src = $"secrets/($secret).age"
    if not ($src | path exists) {
        error make { msg: $"Secret not found: ($src)" }
    }
    mkdir .tmp
    let dest = $".tmp/unencrypted-($secret)"
    agenix -d $src | save -f $dest
    print $"Decrypted to ($dest)"
}

# Encrypt a file to secrets/ folder (re-encrypts using agenix)
export def "skyg encrypt" [secret: string@secret-names, source?: string] {
    cd $REPO_ROOT
    let src = $source | default $".tmp/unencrypted-($secret)"
    if not ($src | path exists) {
        error make { msg: $"Source file not found: ($src)" }
    }
    let dest = $"secrets/($secret).age"
    cat $src | EDITOR="cp /dev/stdin" agenix -e $dest
    print $"Encrypted ($dest)"
}

# Compare unencrypted local version with encrypted version of a secret
export def "skyg compare-secret" [secret: string@secret-names] {
    cd $REPO_ROOT
    let unencrypted = $".tmp/unencrypted-($secret)"
    let encrypted = $"secrets/($secret).age"

    let temp_decrypted = $"/tmp/skyg-compare-($secret)-($env.USER)-(random uuid)"
    agenix -d $encrypted | save -f $temp_decrypted
    print $"Comparing ($unencrypted) with decrypted ($encrypted)"
    try {
        print $"diff -u $(unencrypted) $(temp_decrypted)"
        diff -u $unencrypted $temp_decrypted | print
    } catch {
        print "Files are identical"
    }

    rm -f $temp_decrypted
}
