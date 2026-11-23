# modules/nixos/common/

Baseline settings every Linux host receives. `default.nix` imports each file/subfolder and
sets a few always-on defaults (`EDITOR=vi` unless `skyg.user.enable` makes it nvim, local bin in PATH). `nixpkgs.config.allowUnfree`
is set once in `core.nix`; no host needs to set `NIXPKGS_ALLOW_UNFREE` itself.
Most leaf modules expose a `skyg.nixos.common.*` enable flag and stay inert until switched on.

## Files

```
common/
├── default.nix      # Imports everything below + always-on env defaults
├── core.nix         # System packages, nh (clean + gc), nix-ld, timezone (Toronto), locale; skyg.nixos.common.minimal
├── networking.nix   # skyg.core.hostName, NetworkManager, NFS server opt-in (skyg.nixos.common.networking.nfsServer, default false)
├── user.nix         # skyg.user.createSystemUser — creates the system user/groups + zsh shell
├── user-env.nix     # skyg.user.enable — shell and CLI setup for the user and root (zsh, starship, git, nvim, tmux, …)
├── config-links.nix # skyg.configLinks — symlink files from configs/ into the home dir
├── hm-cleanup.nix   # TEMPORARY — removes links left by home-manager; delete once all hosts switched
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
- **`user-env.nix`** replaced Home Manager. Tools, and anything that needs a store path
  (zsh plugins, starship init, nvim/tmux plugins, direnv, bat, gpg-agent, the git identity),
  are NixOS options and so apply to every user. Plain dotfiles live in `configs/shared/`
  (`zsh/zshrc`, `starship.toml`, `git/config`, `zellij/config.kdl`, `nushell/config.nu`)
  and are linked through `skyg.configLinks`.
- **`config-links.nix`** links each `skyg.configLinks.links.<name>` (`source` under
  `configs/`, `target` under the home dir) for `skyg.user.name`, at login and on every
  switch. By default the link points at a read-only store copy. Hosts with the repo
  checked out set `skyg.configLinks.live = true` to link the checkout instead (falls back
  to the store copy if the file is missing); `baked = true` on a link keeps it read-only
  even then. `root = true` also links it for root, always from the store. A real file in
  the way is moved to `<path>.backup.<timestamp>`.
- **`hm-cleanup.nix`** is temporary: once per home dir it deletes the symlinks
  Home Manager left behind and its GC roots.
- **`ssh-server.nix`** ships the master public keys (`masterPubKeys`, a list so a key can be
  rotated by adding the new one before dropping the old) and a hardened sshd config
  (key-only auth, long keepalives). Disabled by default.
- **`diagnix/`** adds a read-only `diagnix` user (uid 2950) that nbot uses over SSH, via
  `lab-ssh` in the agent system (`server/services/nbot-agent.nix`). It reads logs
  (`systemd-journal` group), units, `/proc` and the store, and can't change anything. It
  can't read root-only files. Through sudo it can run only the fixed `diag-*` scripts
  (docker ps/logs, smart, ports, firewall, btrfs, io, pstore). The key is `restrict,pty` and only
  works from the nbot hosts (`hosts.nix`). `diag-pstore` prints the kernel's saved crash
  records from `/sys/fs/pstore` (root-only), the one trace a hard freeze can leave behind.
  The hermenix VM has its own key (`hosts.nix` → `hermenix`), with the same limits, accepted
  only from hl-fwdesk's addresses (the VM is NAT'ed out of fwdesk). Turn it off per host
  with `skyg.nixos.common.diagnix.hermenix.enable = false`. fwdesk's `hermenix.nix` lets
  the VM reach port 22 on `10.0.10.0/24`. Hosts running nbot also let their own containers
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
skyg.user.enable                 → user-env.nix (options declared in core/user.nix)
skyg.configLinks.*               → config-links.nix
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
