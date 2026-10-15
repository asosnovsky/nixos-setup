use types.nu *
use helpers.nu *

# update some flakes
export def "skyg flake update" [input_name?: string@flake-inputs] {
    cd $REPO_ROOT
    if $input_name == null {
        print "Updating all flakes..."
        nix flake update | print
    } else {
        print $"Updating flake: ($input_name)"
        nix flake update $input_name | print
    }
    git diff flake.lock | print
}

# Run nix flake check
export def "skyg flake check" [] {
    nix flake check --no-build
}

# Validate that all versioned flake inputs use the same NixOS release
export def "skyg flake check-versions" [] {
    let flake = "flake.nix"

    if not ($flake | path exists) {
        print "check-versions: flake.nix not found, skipping"
        return
    }

    # Only scan url lines to avoid false positives from embedded script strings
    let url_lines = (open $flake | lines | enumerate | where { |row|
        ($row.item | str contains "url") and ($row.item =~ 'release-\d+\.\d+')
    })

    let versions = ($url_lines
        | each {|row| $row.item | parse --regex '.*release-(?P<version>\d+\.\d+).*' | get version }
        | flatten
        | uniq)

    if ($versions | length) <= 1 {
        print "check-versions: OK"
        return
    }

    print "check-versions: mismatched NixOS release versions in flake.nix:"
    print ""
    for version in $versions {
        print $"  release-($version):"
        $url_lines | where {|row| $row.item | str contains $"release-($version)" } | each { |row|
            print $"    line ($row.index + 1): ($row.item | str trim)"
        }
    }
    print ""
    print "All versioned inputs (home-manager, stylix, etc.) must use the same NixOS release."
    error make {msg: "Mismatched NixOS release versions"}
}
