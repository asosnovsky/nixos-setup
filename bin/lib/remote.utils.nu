use types.nu *
use profile.nu *

# Read the 3 system paths on a remote host:
#   booted    = what it booted from
#   current   = what is running now (changed by switch/test)
#   next_boot = what the next reboot will use (changed by switch/boot)
export def get-boot-state [target: string] {
    let lines = (bash -c $"ssh -o BatchMode=yes ($target) 'readlink /run/booted-system; readlink /run/current-system; readlink -f /nix/var/nix/profiles/system' 2>/dev/null" | lines)
    let booted = ($lines | get 0? | default "")
    let current = ($lines | get 1? | default "")
    let profile = ($lines | get 2? | default "")
    let next_boot = if $profile == "" { $current } else { $profile }
    {booted: $booted, current: $current, next_boot: $next_boot}
}

export def get-remote-boot-info [ host: string@remote_targets ] {
	let target = $"root@($host).lab.internal"
	let is_online = (try {
      bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 ($target) 'true' >/dev/null 2>&1"
      true
  } catch { false })
	if (not $is_online) {
		return {host: $host, status: "offline", booted: "", current: "", next_boot: "", reboot_pending: false, needs_build: false, local_toplevel: ""}
	}
	return (try {
      # Fetch remote system paths and the local toplevel concurrently.
      let fetched = (["remote" "local"] | par-each {|what|
          if $what == "remote" {
              get-boot-state $target
          } else {
              try {
                  bash -c $"nix eval --raw '.#nixosConfigurations.hl-($host).config.system.build.toplevel.outPath' 2>/dev/null || true" | str trim
              } catch { "" }
          }
      })

      let state = $fetched.0
      let booted = $state.booted
      let current = $state.current
      let next_boot = $state.next_boot
      let local_toplevel = $fetched.1

      # A reboot only matters if it would land on a different system than we booted.
      let reboot_pending = ($booted != "" and $booted != $next_boot)
      let needs_build = if $local_toplevel == "" { "unknown" } else { $local_toplevel != $next_boot }

      {host: $host, status: "online", booted: $booted, current: $current, next_boot: $next_boot, reboot_pending: $reboot_pending, needs_build: $needs_build, local_toplevel: $local_toplevel}
  } catch {
      {host: $host, status: "error", booted: "", current: "", next_boot: "", reboot_pending: false, needs_build: false, local_toplevel: ""}
  })
}


# Poll SSH until the host reaches the desired reachability, or the timeout elapses.
export def wait-for-host [target: string, want_online: bool, timeout: int] {
    let deadline = (date now) + ($timeout * 1sec)
    while (date now) < $deadline {
        let online = (try {
            bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 ($target) 'true' >/dev/null 2>&1"
            true
        } catch { false })
        if $online == $want_online {
            return true
        }
        sleep 3sec
    }
    false
}

# Send a desktop notification if notify-send is available; never fail the caller.
export def notify [title: string, body: string] {
    try {
        ^notify-send $title $body
    } catch { }
}
