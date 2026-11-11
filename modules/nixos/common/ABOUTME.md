# modules/nixos/common/

Baseline settings every Linux host receives. `default.nix` imports each file/subfolder and
sets a few always-on defaults (`EDITOR=vi`, local bin in PATH). `nixpkgs.config.allowUnfree`
is set once in `core.nix`; no host needs to set `NIXPKGS_ALLOW_UNFREE` itself.
Most leaf modules expose a `skyg.nixos.common.*` enable flag and stay inert until switched on.

## Files

```
common/
├── default.nix      # Imports everything below + always-on env defaults
├── core.nix         # System packages, nh (clean + gc), nix-ld, timezone (Toronto), locale; skyg.nixos.common.minimal
├── networking.nix   # skyg.core.hostName, NetworkManager, NFS server opt-in (skyg.nixos.common.networking.nfsServer, default false)
├── user.nix         # skyg.user.createSystemUser — creates the system user/groups + zsh shell
├── fonts.nix        # System font packages + fontconfig defaults (Fira Code, Noto, …); skyg.nixos.common.fonts.minimal
├── ssh-server.nix   # skyg.nixos.common.ssh-server — hardened sshd + master public keys (list)
├── diagnix/         # skyg.nixos.common.diagnix — read-only user nbot uses to diagnose hosts

├── qemu.nix         # skyg.core.qemu — QEMU/quickemu + SPICE guest tooling
├── binary-cache.nix # skyg.nixos.common.cachePush — push finished builds to the bigbox2 cache
├── containers/      # Docker vs Podman runtime selection + host-created container networks
├── hardware/        # GPU, fan control, audio, laptop power, Coral TPU udev
└── pritunl/         # Pritunl VPN client service
```

## Notable details

- **`core.nix`** sets `time.timeZone = "America/Toronto"`, `i18n` to `en_CA.UTF-8`, and enables
  `programs.nh` with auto-clean (`--keep-since 7d --keep 5`, overridable per host via
  `programs.nh.clean.extraArgs`) as the single GC mechanism — no separate cron jobs or
  `nix.gc.automatic`. `skyg.nixos.common.nh.flake` sets the flake path per host.
- **`networking.nix`** defines `skyg.core.hostName`, enables NetworkManager, and disables the
  flaky `NetworkManager-wait-online` unit. The NFS server is **off by default**
  (`skyg.nixos.common.networking.nfsServer.enable = false`); only hosts that export shares
  opt in.
- **`user.nix`** creates the actual system user (in `wheel` + `networkmanager`) with zsh as
  the login shell; gated by `skyg.user.createSystemUser` (default `true`).
- **`ssh-server.nix`** ships the master public keys (`masterPubKeys`, a list so a key can be
  rotated by adding the new one before dropping the old) and a hardened sshd config
  (key-only auth, long keepalives). Disabled by default.
- **`diagnix/`** adds a read-only `diagnix` user (uid 2950) that nbot uses over SSH, via
  `lab-ssh` in the agent system (`server/services/nbot-agent.nix`). It reads logs
  (`systemd-journal` group), units, `/proc` and the store, and can't change anything. It
  can't read root-only files. Through sudo it can run only the fixed `diag-*` scripts
  (docker ps/logs, smart, ports, firewall, btrfs, io). The key is `restrict,pty` and only
  works from the nbot hosts (`hosts.nix`). Hosts running nbot also let their own containers
  reach port 22 and accept them from private IPs outside the LAN. Their IPs are random, so
  they can't be listed. Resources are capped (1G memory, 1 CPU, 256 tasks). The Nix daemon
  is left open on purpose: an allow-list would break nix-serve/buildbot.
  The private key (base64) is `DIAGNIX_KEY` in the `nbot-goose` secret; fwdesk passes it to
  every container via `agent_env`.
  `hosts.nix` also holds each host's address and host key; the agent pins those keys.

## Option Namespace

```
skyg.core.hostName               → networking.nix
skyg.user.createSystemUser       → user.nix
skyg.core.qemu.*                 → qemu.nix
skyg.nixos.common.ssh-server.*   → ssh-server.nix
skyg.nixos.common.diagnix.*      → diagnix/

skyg.nixos.common.cachePush.*    → binary-cache.nix
skyg.nixos.common.minimal             → core.nix (skip heavy always-on system packages)
skyg.nixos.common.nh.flake            → core.nix (flake path for 'nh os' commands, set per host)
skyg.nixos.common.fonts.minimal       → fonts.nix (install only a minimal font set)
skyg.nixos.common.networking.nfsServer → networking.nix (enable/disable the NFS server, default false)
skyg.nixos.common.containers.*         → containers/
skyg.nixos.common.hardware.*     → hardware/
skyg.nixos.common.pritunl.*      → pritunl/
```

## Conventions

- This tree is for behaviour that is reasonable on _any_ Linux host. Anything role-specific
  belongs in `server/` or `desktop/`.
- Hostname-independent defaults can be set directly; anything optional gets an `enable` gate.
