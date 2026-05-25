use types.nu *
use profile.nu *

const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def skyg [] {
    print $REPO_ROOT
    print "Subcommands: profiles, build, switch, test, rollback, update, remote, openwrt, build-iso, hm, decrypt, encrypt"
    print "Run: skyg <subcommand> --help"
}

export def "skyg profiles" [only_remote: bool = false] {
    if $only_remote {
        valid_remote_profiles | print
    } else {
        valid_profiles | print
    }
}

# Build configuration
export def "skyg build" [] {
    cd $REPO_ROOT
    nh os build | print
}

# Switch configuration
export def "skyg switch" [] {
    cd $REPO_ROOT
    nh os switch --ask | print
}

# test configuration
export def "skyg test" [] {
    cd $REPO_ROOT
    nh os test | print
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

# Deploy to remote machine
export def "skyg remote" [
    cmd: string@remote-cmds,
    target: string@remote_targets = "",
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
    age -d -i ~/.ssh/id_ed25519 $src | save -f $dest
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
    cp $src $dest
    agenix -r -i ~/.ssh/id_ed25519
    print $"Encrypted ($dest)"
}
