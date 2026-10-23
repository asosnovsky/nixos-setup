# robotnix — self-managed NixOS nspawn robots

`skyg.nixos.server.robotnix` runs persistent NixOS `systemd-nspawn` containers
("robots") that fully own their own system. Each robot has a real LAN IP, hard
disk limits, btrfs snapshots, and network access the host controls completely.

## Model

- **The robot owns its system.** On first install (`robotnix-<r>-seed.service`)
  the host builds a starting system with the same entry point the robot's own
  flake uses (`lib.nixosSystem` = eval-config with `system = null`), installs it
  into `root.img` with `nixos-install --no-bootloader`, and writes
  `/etc/nixos/{flake.nix,robotnix.nix,configuration.nix}`. After that the host
  never touches the robot's root: it rebuilds with
  `nixos-rebuild switch --flake /etc/nixos` against its own pinned nixpkgs and
  its own store. Changes survive reboots.
- **`robotnix.nix` is host-owned** (network, user, ssh keys, git-sync).
  `configuration.nix` is the robot's own config (`seed.configuration`, default
  `./seed/configuration.nix`). Changing a seed config only matters at the next
  `robotnix reseed`.
- **No host root.** Robots run with `--private-users=pick` unless
  `privateUsers = false`.

## Storage

Per robot under `<baseDir>/<robot>/` (btrfs subvolumes, `nodatacow` images):

```
root/root.img   100G (default) sparse ext4, whole OS incl. /nix
home/home.img    60G (default) sparse ext4, /home
snapshots/<id>/{root,home}     read-only subvolume snapshots
```

The host mounts the images at `/run/robotnix/<robot>/` and passes them in, so a
snapshot freezes both filesystems (`fsfreeze`) for a consistent point in time
while the robot runs. Sizes are hard limits; raise them and the images grow on
the next restart (shrinking is not supported).

Snapshots: per-robot `snapshots.enable/interval/keep` via `skyg.server.timers`
(`robotnix-<r>-snapshot`), `robotnix snapshot|restore|forget|snapshots`.
`restore` saves a `pre-restore` snapshot first. Because images are `nodatacow`,
keep the automatic snapshot count modest — every live snapshot reintroduces
copy-on-write for the referenced blocks. Backups are out of scope for now.

## Network

One routed virtual switch:

- `robotnix-br` bridge (networkd) on 10.78.0.1/24, unmanaged by
  NetworkManager; each robot's `vb-<robot>` port is `Isolated` (no robot-to-
  robot L2).
- Robots hold `<lanIP>/32` with a default route via the switch. The host routes
  to them and answers ARP for that IP on `externalInterface` (proxy ARP per IP;
  global proxy ARP stays off), so each packet passes the host firewall.
- nftables: a bridge table drops spoofed addresses; an `inet robotnix` table
  does the per-robot filtering before `nixos-fw` (priority filter - 10). IPv6
  from robots is dropped (`host0` is IPv4-only). Inbound from the LAN to a
  robot is open on every port — make your own decisions inside the robot.
- Per-robot dnsmasq on the host (port 5300+id) is the robot's only resolver:
  all port 53 is DNAT'd to it, DoT is dropped. The robot cannot change its
  resolv.conf meaningfully; it cannot touch the host's nftables/networkd.

## Access tiers

`access.shared` + `robots.<r>.access` merge per robot (`internet` from the
robot tier wins, all lists are unions). Rule order in the out-chain:

1. established/related
2. port 53 served by the host / 853 dropped (DoT)
3. `blockedCidrs` and blocked-domain IPs (nftsets fed by dnsmasq `nftset=`)
4. `lanAccess` / `hostAccess` endpoints (host input is matched per-robot by
   port-source rules)
5. RFC1918/CGNAT/link-local drop unless `allowLan`
6. internet: `all` (default) or, with `allowlist`, only `allowedCidrs` +
   allowed-domain IPs

Domain rules are IP-based: acceptable for host-controlled filtering, but a
CDN shared with an allowed domain also lets that IP's other sites through (and
dnsmasq learns current IPs). `blockedDomains` resolve to NXDOMAIN; in
allowlist mode everything not allowed is NXDOMAIN + dropped.

## Git-sync of the robot's flake (default)

On first install / reseed, the seed creates a git repo at `/etc/nixos`
(`git.enable`, default on) and sets `git.remoteUrl` as `origin` when given. A
timer inside the robot (`robotnix-flake-gitsync` = `git add -A`, commit, push
if origin exists) runs on `git.interval` (`daily` default). The robot needs the
remote reachable (e.g. through `lanAccess`) and its own credentials if the
remote is private.

## The `robotnix` CLI

Nushell script (`pkgs.writers.writeNuBin`), part of this module:
`list`, `status`, `start/stop/restart`, `shell`, `snapshot`,
`snapshots`, `forget`, `restore`, `reseed [--wipe-home]`, `access`.
Runtime state comes from `/etc/robotnix.json`, written by the module.

## Notes / decisions

- **nspawn, not `oci-containers`**: the server/GUIDELINES rule about
  `oci-containers` targets Docker/Podman. nspawn containers need
  `systemd-nspawn` and the NixOS container init; there is no OCI equivalent.
- This is why `systemd-nspawn` is launched by a hand-written unit rather than
  the `containers.*` module: that module shares the host store, which would
  break the robot's self-rebuilds. The unit mirrors `nixos-containers.nix`
  (`Type=notify`, SIGRTMIN+3, exit status 133, `machine.slice`).
- `systemd-nspawn` runs in `machine.slice` (systemd's nspawn home), not
  `system.slice`.
- Timers use `skyg.server.timers`; eval asserts unique robot ids/IPs, name
  length ≤ 12 (interface-name limit), no clash with
  `skyg.internalNetworkingMap.apps`, and no domain/CIDR both allowed and
  blocked.
- `fsfreeze` fails on unfrozen ro/sparse quirks only when the images are not
  mounted (robot stopped); the CLI snapshots only mounted filesystems' mounts,
  otherwise it snapshots the subvolumes directly.
- flake inputs: only the host nixpkgs is pinned into the robot's flake
  (`github:NixOS/nixpkgs/<host-rev>`). Extra inputs belong in the robot's own
  `configuration.nix` edits.
