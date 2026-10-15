use types.nu *
use helpers.nu *

# Build a bootable image: ISO, or Pi SD card image (fully-baked, no on-device rebuild)
export def "skyg build image" [target: string@image-targets] {
    cd $REPO_ROOT
    let spec = (match $target {
        "iso" => { config: "iso", out: "iso", attr: "isoImage" }
        "pi1" => { config: "hl-pi1", out: "sd-image", attr: "sdImage" }
        "pi2" => { config: "hl-pi2", out: "sd-image", attr: "sdImage" }
        _ => { error make { msg: $"Unknown image target '($target)'. Expected: iso, pi1, pi2" } }
    })
    let imageBuildTime = date now | format date "%Y.%m.%d_%H_%M_%S"
    let rootOutputFolder = $REPO_ROOT | path join "build" $spec.config
    let outPutFolder = $rootOutputFolder | path join $imageBuildTime
    rm -rf $rootOutputFolder
    mkdir $rootOutputFolder
    nix build $"#nixosConfigurations.($spec.config).config.system.build.($spec.attr)" -o $outPutFolder
    printf $outPutFolder
}

# Deploy OpenWrt router configuration
export def "skyg build openwrt" [
    router?: string@router-names,
    --dry-run  # Render configs to .tmp/openwrt-<router>/ without touching the router
] {
    cd $REPO_ROOT
    let router = $router | default "glmain"
    let decrypted_file = skyg secrets show $"($router).json"
    if $dry_run {
        ^cat $decrypted_file | nix run .#openwrt-($router)-dry-run -- ($router)
    } else {
        ^cat $decrypted_file | nix run .#openwrt-($router)
    }
}
