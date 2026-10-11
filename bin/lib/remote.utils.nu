use types.nu *
use profile.nu *

export def get-remote-boot-info [ host: string@remote_targets ] {
	let target = $"root@($host).lab.internal"
	let is_online = (try {
      bash -c $"ssh -o BatchMode=yes -o ConnectTimeout=3 ($target) 'true' >/dev/null 2>&1"
      true
  } catch { false })
	if (not $is_online) {
		return {host: $host, status: "offline", booted: "", current: "", reboot_pending: false, needs_build: false, local_toplevel: ""}
	}
	return (try {
      # Fetch remote system paths and the local toplevel concurrently.
      let fetched = (["remote" "local"] | par-each {|what|
          if $what == "remote" {
              bash -c $"ssh ($target) 'readlink /run/booted-system; readlink /run/current-system' 2>/dev/null" | lines
          } else {
              try {
                  bash -c $"nix eval --raw '.#nixosConfigurations.hl-($host).config.system.build.toplevel.outPath' 2>/dev/null || true" | str trim
              } catch { "" }
          }
      })

      let booted = ($fetched.0 | get 0? | default "")
      let current = ($fetched.0 | get 1? | default "")
      let local_toplevel = $fetched.1

      let reboot_pending = ($booted != $current)
      let needs_build = if $local_toplevel == "" { "unknown" } else { $local_toplevel != $current }

      {host: $host, status: "online", booted: $booted, current: $current, reboot_pending: $reboot_pending, needs_build: $needs_build, local_toplevel: $local_toplevel}
  } catch {
      {host: $host, status: "error", booted: "", current: "", reboot_pending: false, needs_build: false, local_toplevel: ""}
  })
}
