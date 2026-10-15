use types.nu *
use helpers.nu *

# Update one or all packages. With a version, bumps explicitly.
# Without a version, auto-detects the latest from upstream.
#
#   skyg pkgs update --all
#   skyg pkgs update buzz-desktop
#   skyg pkgs update buzz-desktop 0.6.0
export def "skyg pkgs update" [
    pkg_name?: string@updatable-pkgs  # Package to update (omit with --all)
    version?: string                                 # Explicit version (omit for auto-detect)
    --all                                            # Update all packages that have update.sh
] {
    cd $REPO_ROOT

    if $all and $version != null {
        error make {msg: "Cannot use --all with a specific version. Run without --all to bump a single package."}
    }

    let targets = if $all {
        updatable-pkgs
    } else if $pkg_name != null {
        [$pkg_name]
    } else {
        error make {msg: "Specify a package name or use --all to update all packages"}
    }

    if ($targets | length) == 0 {
        print "No updatable packages found (no pkgs/*/update.sh scripts)"
        return
    }

    print $"Updating ($targets | length) package\(s): ($targets | str join ', ')"
    print ""

    for pkg in $targets {
        let update_script = $"pkgs/($pkg)/update.sh"
        if not ($update_script | path exists) {
            print $"⚠️  Skipping ($pkg) — no update.sh"
            continue
        }

        print $"=== ($pkg) ==="
        cd $"pkgs/($pkg)"
        try {
            if $version != null {
                bash $"update.sh ($version)" | print
            } else {
                bash "update.sh" | print
            }
        } catch { |e|
            print $"❌ Failed to update ($pkg): ($e)"
        }
        cd $REPO_ROOT
        print ""
    }

    print ""
    if $version != null {
        print "Bump complete. Review with:"
        git --no-pager diff pkgs/ | print
    } else {
        print "All updates complete. Review with:"
        git --no-pager diff pkgs/ | print
    }
}
