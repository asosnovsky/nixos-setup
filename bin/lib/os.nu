use types.nu *
use profile.nu *
use helpers.nu *

# Build local os
export def "skyg os" [
    cmd: string@os-actions,
    --build-host: string@remote_targets = "",
] {
    cd $REPO_ROOT
    mut runcmd = $"nh os ($cmd)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    $runcmd | print
    bash -c $runcmd
}

# rollback configuration
export def "skyg os rollback" [] {
    sudo nixos-rebuild switch --rollback
}
