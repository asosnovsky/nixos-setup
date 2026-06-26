# modules/nixos/common/

Baseline settings every Linux host receives. `default.nix` imports each file/subfolder and
sets a few always-on defaults (`EDITOR=vi`, `NIXPKGS_ALLOW_UNFREE`, local bin in PATH).
Most leaf modules expose a `skyg.nixos.common.*` enable flag and stay inert until switched on.

## Files

```
common/
├── default.nix      # Imports everything below + always-on env defaults
├── core.nix         # System packages, nh, nix-ld, timezone (Toronto), locale, GC cron
├── networking.nix   # skyg.core.hostName, NetworkManager, NFS server
├── user.nix         # skyg.user.createSystemUser — creates the system user/groups + zsh shell
├── fonts.nix        # System font packages + fontconfig defaults (Fira Code, Noto, …)
├── ssh-server.nix   # skyg.nixos.common.ssh-server — hardened sshd + master pubkey
├── qemu.nix         # skyg.core.qemu — QEMU/quickemu + SPICE guest tooling
├── containers/      # Docker vs Podman runtime selection
├── hardware/        # GPU, fan control, audio, laptop power, Coral TPU udev
└── pritunl/         # Pritunl VPN client service
```

## Notable details

- **`core.nix`** sets `time.timeZone = "America/Toronto"`, `i18n` to `en_CA.UTF-8`, enables
  `programs.nh` with auto-clean, and adds a daily `nix-collect-garbage --delete-older-than 7d`
  cron job for both root and the user.
- **`networking.nix`** defines `skyg.core.hostName`, enables NetworkManager + the NFS server,
  and disables the flaky `NetworkManager-wait-online` unit.
- **`user.nix`** creates the actual system user (in `wheel` + `networkmanager`) with zsh as
  the login shell; gated by `skyg.user.createSystemUser` (default `true`).
- **`ssh-server.nix`** ships the master public key and a hardened sshd config
  (key-only auth, long keepalives). Disabled by default.

## Option Namespace

```
skyg.core.hostName               → networking.nix
skyg.user.createSystemUser       → user.nix
skyg.core.qemu.*                 → qemu.nix
skyg.nixos.common.ssh-server.*   → ssh-server.nix
skyg.nixos.common.containers.*   → containers/
skyg.nixos.common.hardware.*     → hardware/
skyg.nixos.common.pritunl.*      → pritunl/
```

## Conventions

- This tree is for behaviour that is reasonable on *any* Linux host. Anything role-specific
  belongs in `server/` or `desktop/`.
- Hostname-independent defaults can be set directly; anything optional gets an `enable` gate.
