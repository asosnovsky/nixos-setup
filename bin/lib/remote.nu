use types.nu *
use profile.nu *
use helpers.nu *
use remote.utils.nu *

# Deploy to remote machine
export def "skyg remote" [
    cmd: string@os-actions,
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
    mut runcmd = $"nh os ($cmd) --no-nom --target-host ($target_host) --ask .#($profile)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    $runcmd | print
    bash -c $runcmd
}

# Fresh-install a remote machine via nixos-anywhere, using its disko config.
# Always reformats every disk in the disko file — a second run is as destructive as the first.
# Missing disko file, live disk OS (without --force-wipe), or mistyped hostname all abort.
export def "skyg remote install" [
    target: string@remote_targets,
    --force-wipe, # wipe even if the host already runs NixOS from disk
] {
    cd $REPO_ROOT
    let target_host = $"root@($target).lab.internal"
    let profile = $"hl-($target)"
    if not (is-valid-profile $profile true) {
        print $"Invalid Remote Profile '(ansi green_bold)($target)(ansi reset)', please select one of:"
        return (remote_targets)
    }
    let disko_file = $"hosts/($profile).disko.nix"
    if not ($disko_file | path exists) {
        error make {msg: $"Missing disko config: ($disko_file). Refusing to install ($profile) without a disko layout."}
    }

    print ""
    print $"(ansi red_bold)WARNING: this WIPES every disk listed in ($disko_file).(ansi reset)"
    print "This is not a switch. Use `skyg remote switch` / `skyg remote boot` to update an installed host."
    print ""
    print "Disks in the disko file:"
    let disks = (
        open $disko_file
        | lines
        | where {|l| ($l | str contains "device") and ($l | str contains "=") }
        | each {|l| $l | str trim }
    )
    for line in $disks {
        print $"  ($line)"
    }
    print ""

    let ssh = $"ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new ($target_host)"
    let root_fstype = (try {
        bash -c $"($ssh) 'findmnt -n -o FSTYPE /' 2>/dev/null" | str trim
    } catch { "" })

    if $root_fstype == "" {
        print $"(ansi yellow)Could not SSH to ($target_host) to check for a live OS.(ansi reset)"
    } else {
        print $"Remote / fstype: ($root_fstype)"
        let installer_fs = ["overlay" "tmpfs" "squashfs"]
        if not ($root_fstype in $installer_fs) {
            if not $force_wipe {
                error make {msg: $"($target_host) already boots from disk (root fstype ($root_fstype)). Refusing to wipe. Use `skyg remote switch ($target)` to update, or pass --force-wipe to reinstall."}
            }
            print $"(ansi yellow)--force-wipe set: proceeding against a live disk OS.(ansi reset)"
        } else {
            print "Remote looks like an installer live image (ok to install)."
        }
    }

    let confirm = input $"Type ($target) to continue: " | str trim
    if $confirm != $target {
        error make {msg: $"Aborted: typed '($confirm)', expected '($target)'."}
    }

    $"Installing [(ansi green_bold)($profile)(ansi reset)] on ($target_host) via nixos-anywhere, using ($disko_file)" | print
    let runcmd = $"nix run github:nix-community/nixos-anywhere -- --flake .#($profile) ($target_host)"
    $runcmd | print
    let bash_path = which bash | get 0.path
    with-env { SHELL: $bash_path } {
        bash -c $runcmd
    }
}

# Boot all remote hosts except the current machine (fwbook)
# Checks online status first, runs `skyg remote boot --build-host fwdesk <host>` for each online host,
# and writes a summary report to .tmp/boot-report.txt

export def "skyg remote boot-all" [] {
    cd $REPO_ROOT
    mkdir .tmp
    let current_host = "fwbook"
    let report_file = ".tmp/boot-report.txt"

    # Discover remote targets from the flake (same logic as skyg remote)
    let all_hosts = remote_targets | where {|h| $h != $current_host }

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
            print $"(ansi green)ONLINE(ansi reset): ($host)"
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
            let runcmd = $"nh os boot --no-nom --target-host ($target_host) .#($profile)"
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
    let timestamp = date now | format date "%Y-%m-%d %H:%M:%S"
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

export def "skyg remote status" [
    target?: string@remote_targets,
    --all  # Check status of all remote hosts
] {
    if $all {
        skyg remote status-all
    } else if $target != null {
        get-remote-boot-info $target
    } else {
        error make {msg: "Specify a target host or use --all"}
    }
}

# Check status of all remotes: generation, pending reboot, needs rebuild
export def "skyg remote status-all" [] {
    cd $REPO_ROOT
    mkdir .tmp
    let current_host = "fwbook"
    let report_file = ".tmp/status-report.txt"

    let all_hosts = remote_targets | where {|h| $h != $current_host }
    print $"Checking status for ($all_hosts | length) remotes..."

    let results = ($all_hosts | par-each { |host|
        let info = get-remote-boot-info $host

        # Print each host's status as one block, as soon as it finishes.
        let booted = (if ($info.booted | is-empty) { "-" } else { $info.booted | path basename })
        let current = (if ($info.current | is-empty) { "-" } else { $info.current | path basename })
        let next_boot = (if ($info.next_boot | is-empty) { "-" } else { $info.next_boot | path basename })
        let reboot_line = if $info.reboot_pending { $"(ansi yellow)REBOOT PENDING(ansi reset)\n" } else { "" }
        # needs_build is true, false, or "unknown" (local eval failed)
        let build_line = match $info.needs_build {
            true => $"(ansi red)NEEDS NEW BUILD(ansi reset)",
            false => $"(ansi green)UP TO DATE(ansi reset)",
            _ => $"(ansi yellow)BUILD UNKNOWN (eval failed)(ansi reset)",
        }
        print $"($host) | Booted:  ($booted) | Current: ($current) | Next boot: ($next_boot)\n  ($reboot_line)($build_line)"

        $info
    })

    return ($results | select host status reboot_pending needs_build)
}

# Reboot every remote host that is pending a reboot (booted-system != next-boot generation).
# Detects pending hosts, lists them, asks for confirmation, then reboots each one at a
# time, waiting for it to come back online and sending a desktop notification when it does.
export def "skyg remote reboot-pending" [] {
    cd $REPO_ROOT
    mkdir .tmp
    let current_host = "fwbook"
    let report_file = ".tmp/reboot-pending-report.txt"

    let all_hosts = remote_targets | where {|h| $h != $current_host }
    print $"Checking ($all_hosts | length) remotes for pending reboots..."

    # Phase 1: find hosts that are online and pending a reboot
    mut pending = []
    mut offline = []
    mut up_to_date = []

    for host in $all_hosts {
        let target = $"root@($host).lab.internal"
        let online = (try {
            bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new ($target) 'true' >/dev/null 2>&1"
            true
        } catch { false })

        if not $online {
            print $"(ansi yellow)OFFLINE(ansi reset): ($host)"
            $offline = ($offline | append $host)
            continue
        }

        let info = (try {
            let s = (get-boot-state $target)
            {booted: $s.booted, next_boot: $s.next_boot, pending: ($s.booted != "" and $s.booted != $s.next_boot)}
        } catch {
            {booted: "", next_boot: "", pending: false}
        })

        if $info.pending {
            print $"(ansi blue)REBOOT PENDING(ansi reset): ($host) booted=($info.booted | path basename) next=($info.next_boot | path basename)"
            $pending = ($pending | append $host)
        } else {
            print $"(ansi green)UP TO DATE(ansi reset): ($host)"
            $up_to_date = ($up_to_date | append $host)
        }
    }

    if ($pending | length) == 0 {
        print ""
        print "No remotes are pending a reboot."
        return
    }

    # Phase 2: confirm before rebooting anything
    print ""
    print $"(ansi yellow_bold)($pending | length) remote\(s\) pending a reboot:(ansi reset)"
    for host in $pending {
        print $"  - ($host)"
    }
    print ""
    let confirm = (input $"Reboot these ($pending | length) host\(s\)? [y/N]: " | str trim | str downcase)
    if not ($confirm in ["y" "yes"]) {
        print "Aborted — no hosts were rebooted."
        return
    }

    # Phase 3: reboot each pending host one at a time, waiting for it to come back
    mut rebooted = []
    mut failed = []
    for host in $pending {
        let target = $"root@($host).lab.internal"
        print $"\n=== Rebooting ($host) ==="

        # Capture the boot id so we can confirm the host actually rebooted.
        let boot_id_before = (try {
            bash -c $"ssh -o BatchMode=yes ($target) 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null" | str trim
        } catch { "" })

        let runcmd = $"ssh -o BatchMode=yes -o ConnectTimeout=5 ($target) 'systemctl reboot'"
        print $runcmd
        # The SSH connection drops as the host shuts down, so a non-zero exit is
        # expected here and does not mean the reboot failed.
        try {
            bash -c $"($runcmd) 2>/dev/null"
        } catch { }

        print $"Waiting for ($host) to shut down..."
        let went_down = (wait-for-host $target false 90)
        if not $went_down {
            print $"(ansi yellow)($host) did not go offline within 90s — continuing to wait for it to come back.(ansi reset)"
        }

        print $"Waiting for ($host) to come back online..."
        let came_up = (wait-for-host $target true 300)
        if $came_up {
            let boot_id_after = (try {
                bash -c $"ssh -o BatchMode=yes ($target) 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null" | str trim
            } catch { "" })
            # Proof of reboot: boot id changed. If we can't read it, fall back to "it went offline".
            let did_reboot = if $boot_id_before != "" and $boot_id_after != "" {
                $boot_id_before != $boot_id_after
            } else {
                $went_down
            }
            if not $did_reboot {
                print $"(ansi red)($host) answered but did NOT reboot (same boot id, never went offline)(ansi reset)"
                notify $"❌ ($host) did not reboot" "Reboot command had no effect"
                $failed = ($failed | append $host)
                continue
            }

            # Check the host really came up on the generation we wanted.
            let after = (try { get-boot-state $target } catch { null })
            if $after != null and $after.booted != $after.next_boot {
                print $"(ansi red)($host) rebooted but is NOT on its latest generation(ansi reset)"
                print $"  booted=($after.booted | path basename)"
                print $"  wanted=($after.next_boot | path basename)"
                notify $"⚠️ ($host) wrong generation" "Rebooted but not on the latest generation"
                $failed = ($failed | append $host)
                continue
            }

            print $"(ansi green)($host) rebooted and is back online(ansi reset)"
            notify $"✅ ($host) rebooted" "Back online and reachable"
            $rebooted = ($rebooted | append $host)
        } else {
            print $"(ansi red)($host) did not come back online within 300s(ansi reset)"
            notify $"❌ ($host) did not come back" "Still unreachable after 300s"
            $failed = ($failed | append $host)
        }
    }

    # Write report
    let timestamp = date now | format date "%Y-%m-%d %H:%M:%S"
    let report = $"Reboot-Pending Report - ($timestamp)

Total hosts considered: ($all_hosts | length)
Pending reboot: ($pending | length) - ($pending | str join ', ')
Rebooted: ($rebooted | length) - ($rebooted | str join ', ')
Failed: ($failed | length) - ($failed | str join ', ')
Offline: ($offline | length) - ($offline | str join ', ')
Up to date: ($up_to_date | length) - ($up_to_date | str join ', ')
"

    $report | save -f $report_file
    print $"
Report written to ($report_file)"
    print $report
}
