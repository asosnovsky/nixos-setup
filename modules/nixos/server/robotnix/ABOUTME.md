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
- Guards in the same table, so other modules' NAT can't reroute robot
  traffic (hermenix once DNAT'd any-destination traffic on some ports into
  its VM):
  - a connection meant for a robot IP that leaves anywhere but the switch,
    or lands on the host itself, is dropped (`ct original ip daddr`; replies
    are untouched via `ct direction original`);
  - a robot's own new connection that was DNAT'd is dropped. The robot DNS
    redirect still works: it goes to the host (input), not forward.
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

## Ephemeral robots (opt-in)

`ephemeral = true` resets root to a clean copy of the seed on every start
(host boot, `robotnix restart`, or a reboot inside). Only `/home` survives.

- The seed step saves the fresh root as a read-only subvolume
  `<base>/pristine` before the robot first boots, plus `pristine.id` (hash of
  the seed system and the files it installs).
- Before each start, `robotnix-<r>-reset.service` unmounts root, swaps
  `<base>/root` for a snapshot of `pristine`, and remounts (about a second).
  It is its own oneshot (no `RemainAfterExit`, so every robot start re-runs
  it) because the robot unit's `DevicePolicy=closed` blocks the loop devices
  the mount needs.
- When the seed changes, the storage step sees a different id on the next
  host switch, wipes root, and the seed step reinstalls (a few minutes).
- `persist = [ "/var/lib/..." ]` keeps folders: stored in `/home/.persist`
  inside the home image and bind-mounted at their usual path. SSH host keys
  always go to `/home/.persist/ssh`, so they don't change each boot.
- The robot still has its own writable store, so `nix`/`devenv` work until
  the next restart. Changes go through `seed.configuration` on the host.
- Snapshots and `restore` cover home only; `reseed` drops `pristine` too.
- git-sync can't work (fresh repo each start): eval asserts it is off.

## Hermes in every robot (opt-in)

`hermes.enable` (shared) runs one Hermes agent per robot with the upstream
`services.hermes-agent` module; `robots.<r>.hermes.enable` can opt out.

- The robot's flake gets a `hermes-agent` input pinned to the host's locked
  rev, and the host's seed build includes the same module.
- Host-managed: `hermes.settings` (shared + robot, deep-merged) goes to
  config.yaml; `hermes.name` writes SOUL.md ("You are <name>, a Hermes-based
  agent ...") on every boot; null keeps the stock identity.
- Secrets: `hermes.environmentFiles` (shared + robot, KEY=value, e.g. agenix)
  are passed with `--load-credential` and loaded by the `hermes-agent` unit
  from `/run/credentials/@system/robotnix-hermes-<n>` (later files win). No
  file ownership games with the user namespace. Restart the robot after a
  secret changes.
- The `hermes` user/group have a fixed id (870) so kept files stay owned
  right across reinstalls; the login user is in the `hermes` group and has
  the `hermes` CLI.
- Ephemeral robots keep only `cron/`, `memories/` and `skills/` of
  `/var/lib/hermes/.hermes` (added to `persist` automatically). Sessions,
  logs, OAuth logins and pairings reset each start: use API keys and
  `*_ALLOWED_USERS` env vars instead.
- Gateway API (`hermes.gateway`, on by default, port 8642): the host sets
  `services.hermes-agent.environment` (`API_SERVER_ENABLED`, `_HOST=0.0.0.0`,
  `_PORT`, `_MODEL_NAME` = `hermes.name` or the robot name). These go to
  `$HERMES_HOME/.env`, which beats the same names in the secrets. Each
  robot's secrets need `API_SERVER_KEY`, or the API server won't start.
- Dashboard (`hermes.dashboard`, on by default, port 80):
  `backend.mode = "dashboard"` on 0.0.0.0, run as `hermes-backend.service`
  with the same secret files, plus `CAP_NET_BIND_SERVICE` when the port is
  below 1024. A non-loopback dashboard needs a login in the secrets:
  `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`, `..._PASSWORD_HASH` (or
  `..._PASSWORD`) and `..._SECRET` (keeps sessions across restarts). Without
  one it exits and systemd keeps restarting it; the gateway keeps working.
  Port 80 may clash with the robot's own compose stacks: change the port.
- Both: top-level `enable/port/openFirewall`, robots override any of them
  (null = follow). `openFirewall` opens the TCP port in the robot's own
  firewall. Eval asserts the two don't share a port.
- Existing robots only get Hermes (and gateway/dashboard changes) after
  `robotnix reseed` (flake.nix and robotnix.nix are written at install).
  Ephemeral robots pick changes up on the next host switch.

## Docker and Tailscale (opt-in, host side only)

These options only change what the host allows. Turn the service on in the
robot's own config (e.g. its `seed.configuration`).

- `allowDocker`: nspawn gets `--system-call-filter=add_key keyctl bpf`
  (blocked by default, Docker needs them). Docker runs inside the robot's user
  namespace, so images using UIDs above 65535 won't run.
- `allowTun`: `/dev/net/tun` is bound in and allowed on the unit
  (`DevicePolicy=closed` blocks it otherwise). Used for tailscale: the robot
  is its own tailnet machine, log in once inside with `sudo tailscale up`.
  Direct LAN paths to other tailnet peers hit the private-range drop, so it
  uses public endpoints or DERP.
- Both apply on the next robot restart; no reseed needed.

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
- The robot's root gets `/usr/bin` before its first start: `systemd-nspawn`
  refuses a tree without `/usr` ("doesn't look like it has an OS tree"), the
  same reason `nixos-containers.nix` creates it. The seed's tail block runs on
  every start, so no reseed is needed after this landed.
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
