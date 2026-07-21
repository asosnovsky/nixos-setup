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

# Validate that all versioned flake inputs use the same NixOS release
export def "skyg check-flake-versions" [] {
    let flake = "flake.nix"

    if not ($flake | path exists) {
        print "check-flake-versions: flake.nix not found, skipping"
        return
    }

    # Only scan url lines to avoid false positives from embedded script strings
    let url_lines = (open $flake | lines | enumerate | where { |row|
        ($row.item | str contains "url") and ($row.item =~ 'release-\d+\.\d+')
    })

    let versions = ($url_lines
        | each { |row| $row.item | parse --regex '.*release-(?P<version>\d+\.\d+).*' | get version }
        | flatten
        | uniq)

    if ($versions | length) <= 1 {
        print "check-flake-versions: OK"
        return
    }

    print "check-flake-versions: mismatched NixOS release versions in flake.nix:"
    print ""
    for version in $versions {
        print $"  release-($version):"
        $url_lines | where { |row| $row.item | str contains $"release-($version)" } | each { |row|
            print $"    line ($row.index + 1): ($row.item | str trim)"
        }
    }
    print ""
    print "All versioned inputs (home-manager, stylix, etc.) must use the same NixOS release."
    error make { msg: "Mismatched NixOS release versions" }
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
	--build-host: string@remote_targets = "",
	# --max-jobs: int = 0,
	# --cores: int = -1,
] {
    cd $REPO_ROOT
    mut runcmd = $"nh os ($cmd)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    # if $max_jobs > 0 {
    #     $runcmd = $"($runcmd) --max-jobs ($max_jobs)"
    # }
    # if $cores >= 0 {
    #     $runcmd = $"($runcmd) --cores ($cores)"
    # }
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

# Boot all remote hosts except the current machine (fwbook)
# Checks online status first, runs `skyg remote boot --build-host fwdesk <host>` for each online host,
# and writes a summary report to .tmp/boot-report.txt

export def "skyg remote boot-all" [
    --build-host: string@remote_targets = "fwdesk"  # Builder host to use for all boots
] {
    cd $REPO_ROOT
    mkdir .tmp
    let current_host = "fwbook"
    let report_file = ".tmp/boot-report.txt"

    # Discover remote targets from the flake (same logic as skyg remote)
    let all_hosts = (remote_targets | where { |h| $h != $current_host })

    print $"Found ($all_hosts | length) candidate hosts excluding ($current_host)"

    mut successes = []
    mut failures = []
    mut skipped = []

    # Phase 1: sequential SSH reachability checks (fast)
    mut online_hosts = []
    for host in $all_hosts {
        print $"\n=== Checking ($host) ==="
        let target = $"root@($host).lab.internal"
        let is_online = (try {
            bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new ($target) 'true' >/dev/null 2>&1"
            true
        } catch { false })

        if not $is_online {
            print $"(ansi yellow)OFFLINE(ansi reset): ($host)"
            $skipped = ($skipped | append $host)
        } else {
            print $"(ansi green)ONLINE(ansi reset): ($host) - will boot via ($build_host)"
            $online_hosts = ($online_hosts | append $host)
        }
    }

    # Phase 2: run boots in parallel (2 concurrent) without interactive prompts
    if ($online_hosts | length) > 0 {
        print "
Starting parallel boots (concurrency: 2)..."
        let boot_results = ($online_hosts | par-each --threads 1 { |host|
            let target_host = $"root@($host).lab.internal"
            let profile = $"hl-($host)"
            let runcmd = $"nh os boot --target-host ($target_host) --build-host ($build_host).lab.internal .#($profile)"
            print $runcmd
            let ok = (try {
                bash -c $runcmd
                true
            } catch {
                false
            })
            {host: $host, success: $ok}
        })

        for r in $boot_results {
            if $r.success {
                $successes = ($successes | append $r.host)
                print $"(ansi green)SUCCESS(ansi reset): ($r.host)"
            } else {
                $failures = ($failures | append $r.host)
                print $"(ansi red)FAILED(ansi reset): ($r.host)"
            }
        }
    }

    # Write report
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    let report = $"Boot Report - ($timestamp)

Total hosts considered: ($all_hosts | length)
Skipped offline: ($skipped | length) - ($skipped | str join ', ')
Successful: ($successes | length) - ($successes | str join ', ')
Failed: ($failures | length) - ($failures | str join ', ')

Details:
  Online & Booted: ($successes | str join ', ')
  Offline: ($skipped | str join ', ')
  Failed: ($failures | str join ', ')
"

    $report | save -f $report_file
    print $"
Report written to ($report_file)"
    print $report
}

# Check status of all remotes: generation, pending reboot, needs rebuild
export def "skyg remote status" [] {
    cd $REPO_ROOT
    mkdir .tmp
    let current_host = "fwbook"
    let report_file = ".tmp/status-report.txt"

    let all_hosts = (remote_targets | where { |h| $h != $current_host })
    print $"Checking status for ($all_hosts | length) remotes..."

    let results = ($all_hosts | each { |host|
        print $"
=== ($host) ==="
        let target = $"root@($host).lab.internal"
        let online = (try {
            bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 ($target) 'true' >/dev/null 2>&1"
            true
        } catch { false })

        if not $online {
            print $"(ansi yellow)OFFLINE(ansi reset)"
            return {host: $host, status: "offline", booted: "", current: "", reboot_pending: false, needs_build: false}
        }

        let info = (try {
            let booted = (bash -c $"ssh ($target) 'readlink /run/booted-system' 2>/dev/null" | str trim)
            let current = (bash -c $"ssh ($target) 'readlink /run/current-system' 2>/dev/null" | str trim)
            let reboot_pending = ($booted != $current)

            # Compare what the local flake currently evaluates to vs remote's active system
            let local_toplevel = (try {
                (bash -c $"nix eval --raw '.#hl-($host).config.system.build.toplevel.outPath' 2>/dev/null || true") | str trim
            } catch { "" })
            let needs_build = if $local_toplevel == "" { false } else { $local_toplevel != $current }

            {host: $host, status: "online", booted: $booted, current: $current, reboot_pending: $reboot_pending, needs_build: $needs_build}
        } catch {
            {host: $host, status: "error", booted: "", current: "", reboot_pending: false, needs_build: false}
        })

        print $"Booted:  ($info.booted | path basename)"
        print $"Current: ($info.current | path basename)"
        if $info.reboot_pending {
            print $"(ansi yellow)REBOOT PENDING(ansi reset)"
        }
        if $info.needs_build {
            print $"(ansi red)NEEDS NEW BUILD(ansi reset)"
        } else {
            print $"(ansi green)UP TO DATE(ansi reset)"
        }

        $info
    })

    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    let lines = ($results | each { |r|
        if $r.status == "offline" {
            $"- ($r.host): (ansi yellow)OFFLINE(ansi reset)"
        } else if $r.status == "error" {
            $"- ($r.host): (ansi red)ERROR querying status(ansi reset)"
        } else {
            let pending = if $r.reboot_pending { $" [(ansi blue)REBOOT PENDING(ansi reset)]" } else { "" }
            let build = if $r.needs_build { $" [(ansi red)NEEDS REBUILD(ansi reset)]" } else { $" [(ansi green)current(ansi reset)]" }
            $"- ($r.host): booted=($r.booted | path basename) current=($r.current | path basename)($pending)($build)"
        }
    })
    let report = $"Remote Status Report - ($timestamp)

" + ($lines | str join "
") + "
"

    $report | save -f $report_file
    print $"
Report written to ($report_file)"
    print $report
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
        let encrypted = $"secrets/($secret).age"
        if ($encrypted | path exists) {
            agenix -d $encrypted | save -f $src
        } else {
            touch $src
        }
    }
    vi $src
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
