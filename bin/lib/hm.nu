use types.nu *
use profile.nu *
use helpers.nu *

# Home Manager operations
export def "skyg hm" [
    action: string@hm-actions,
    profile: string@valid_profiles = "ari",
] {
    cd $REPO_ROOT
    $"Running home-manager ($action) for profile ($profile)" | print
    home-manager $action --flake $".#($profile)"
}
