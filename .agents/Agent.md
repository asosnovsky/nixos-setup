# Agent Context: nixos-setup

A complete reference for an AI agent to understand, navigate, and modify this
NixOS homelab configuration repository.

---

## Repository Purpose

A **NixOS flake** managing multiple machines (laptops, desktops, servers) and one OpenWrt
router for a personal homelab. Everything is declarative Nix. No imperative scripts except
the `skyg` CLI wrapper and the OpenWrt deploy script.

The configured user, default system architecture, and NixOS state version are all defined
in `flake.nix` (the `lib =` binding at the top of `outputs`). Check that file for
source-of-truth values rather than relying on any hardcoded constants here.

---

## Repository Layout

```
nixos-setup/
├── flake.nix                     # All outputs: nixosConfigurations, homeConfigurations, packages, devShells
├── flake.lock                    # Locked input revisions — do not edit by hand
├── secrets.nix                   # agenix: maps .age files → authorized SSH public keys
├── bin/
│   ├── skyg                      # Bash shim: exec nu --commands "use lib/cmds.nu *; skyg $*"
│   └── lib/
│       ├── cmds.nu               # All skyg subcommands (NuShell — source of truth)
│       ├── profile.nu            # Profile helpers and tab-completion data
│       └── types.nu              # Type definitions
├── hosts/
│   ├── <hostname>.nix            # One file per managed machine
│   ├── <hostname>.hardware-configuration.nix
│   ├── iso.nix                   # Bootable install image
│   └── scripts/                  # Host-specific helper scripts
├── modules/
│   ├── lib.nix                   # makeNixOs / makeIso / makeHomeManagerUsers / makeDarwinModule / eachSystem
│   ├── main.nix                  # Base module every host gets: core/ + nixos/ + network-drives.nix
│   ├── skyg-utils.nix            # makeHyperlinkScriptToConfigs (symlinks configs/ → ~/.config/)
│   ├── macos.nix                 # macOS/nix-darwin module
│   ├── network-drives.nix        # skyg.networkDrives — NFS auto-mounts
│   ├── core/
│   │   ├── default.nix           # Imports: user.nix, macos.nix, nix-substituters.nix
│   │   ├── user.nix              # skyg.user.* and skyg.home-manager.* options; wires HM
│   │   ├── nix-substituters.nix  # Binary caches + remote builder config
│   │   └── macos.nix             # Pipx workaround overlay; distributed build config
│   ├── home/
│   │   ├── default.nix           # makeCommonUser / makeRootUser factories
│   │   ├── programs.nix          # bat, neovim, direnv, eza, starship, nushell, carapace, zsh, zellij, tmux
│   │   ├── services.nix          # gpg-agent with SSH support
│   │   ├── fonts.nix             # Font packages
│   │   └── git.nix               # makeCommonGitConfigs
│   ├── nixos/
│   │   ├── default.nix           # Imports: common/ + server/ + desktop/
│   │   ├── common/
│   │   │   ├── core.nix          # nix-ld, nh, appimage-run, GC cron, timezone, locale
│   │   │   ├── networking.nix    # skyg.core.hostName; NetworkManager; disables nm-wait-online
│   │   │   ├── user.nix          # System user creation; zsh as default shell
│   │   │   ├── ssh-server.nix    # skyg.nixos.common.ssh-server.enable; key-only SSH
│   │   │   ├── qemu.nix          # skyg.core.qemu.enable; QEMU + SPICE stack
│   │   │   ├── fonts.nix
│   │   │   ├── hardware/         # amdgpu, nvidia, coral-tpu-udev, fan2go, fancontrol, laptop-power, pipewire, sound
│   │   │   ├── containers/       # Docker/Podman options; local registry config; metrics port
│   │   │   └── pritunl/          # Pritunl VPN client
│   │   ├── server/
│   │   │   ├── admin.nix         # skyg.server.admin.enable → www-data group
│   │   │   ├── exporters.nix     # skyg.server.exporters.enable → Prometheus node exporter
│   │   │   ├── timers.nix        # skyg.server.timers attrset → systemd timer+service pairs
│   │   │   ├── k3s/              # skyg.nixos.server.k3s.{enable,role,envPath}
│   │   │   ├── k8s/              # Raw Kubernetes: master.nix + node.nix
│   │   │   ├── dns/              # certbot/, routing/ (dnsmasq), local-ca/
│   │   │   ├── arrs/             # Prowlarr + DB for *arr stack
│   │   │   └── services/         # ai-services, audiobookshelf, comfyui, dockge, jellyfin, scrypted
│   │   └── desktop/
│   │       ├── default.nix       # skyg.nixos.desktop.enable; PipeWire, dbus, portals, avahi
│   │       ├── wayland.nix       # NIXOS_OZONE_WL=1, xwayland
│   │       ├── tiler/            # DankMaterialShell + niri + hyprland + swww
│   │       ├── stylix/           # skyg.nixos.desktop.stylix.enable
│   │       ├── gnome.nix / kde.nix / cosmic.nix
│   │       ├── crypto.nix        # skyg.nixos.desktop.crypto.enable
│   │       ├── packages.nix
│   │       └── printers.nix
│   └── openwrt/
│       ├── default.nix           # Builds openwrt-gen Rust binary; exports deployScript
│       └── generator/            # Rust: stdin JSON → dnsmasq.conf or ethers
├── openwrt-routers/
│   └── <router>.nix              # Per-router config (IP, SSH user, configSecret path)
├── secrets/
│   └── *.age                     # Encrypted secrets (see secrets.nix for authorization map)
├── configs/
│   ├── niri/                     # niri compositor config (symlinked to ~/.config/niri)
│   ├── hypr/                     # Hyprland config
│   ├── hyprpanel/                # HyprPanel config
│   └── extra.nu                  # Extra NuShell config
└── docs/                         # Documentation (hosts, modules, secrets, DNS, OpenWrt)
```

**For the full host list and per-machine details**, see `docs/hosts/README.md`.

---

## skyg CLI Reference

`skyg` is implemented in `bin/lib/cmds.nu`. All commands `cd` to `$REPO_ROOT` first.
The `bin/skyg` file is a thin bash shim — the NuShell file is the source of truth.

### System Deployment

```bash
# Local system (whichever host the repo is checked out on)
skyg os switch
skyg os test
skyg os switch --build-host <builder>   # offload compilation to a remote builder

# Remote system
skyg remote switch <hostname>           # deploys to root@<hostname>.<domain>
skyg remote test <hostname>             # test without activating
skyg remote switch <hostname> --build-host <builder>

# Rollback
skyg rollback                           # sudo nixos-rebuild switch --rollback

# Validate flake without building
skyg check                              # nix flake check --no-build
```

`skyg remote` maps `<hostname>` → NixOS profile `hl-<hostname>` → SSH target
`root@<hostname>.<domain>`. See `bin/lib/profile.nu` for the full list of valid targets.

### Home Manager

```bash
skyg hm switch            # apply for the default profile
skyg hm build             # build only
skyg hm switch <profile>  # explicit profile name
```

### Flake Updates

```bash
skyg update               # nix flake update (all inputs) + shows flake.lock diff
skyg update <input>        # update a single input, e.g. skyg update nixpkgs
```

### OpenWrt

```bash
skyg openwrt              # decrypt router secret, pipe to deploy script
skyg openwrt <router>     # explicit router name (matches openwrt-routers/<router>.nix)
```

Deploy flow: age-decrypts the router's JSON secret → generates `dnsmasq.conf` + `ethers`
via the Rust binary → shows colored diffs → prompts for confirmation × 2 → SSHes to the
router → validates with `dnsmasq --test` → restarts dnsmasq (auto-reverts on failure).

### ISO

```bash
skyg build-iso    # nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

### Secrets

```bash
skyg secrets                     # list known secret names
skyg decrypt <name>              # decrypt → .tmp/unencrypted-<name>
skyg encrypt <name> [source]     # re-encrypt ← .tmp/unencrypted-<name>
skyg compare-secret <name>       # diff .tmp/unencrypted-<name> vs the .age file
```

### Profiles

```bash
skyg profiles           # list all configured profiles
skyg profiles true      # list remote-only profiles (hl-* prefixed)
```

---

## Flake Outputs

```nix
nixosConfigurations = {
  # One entry per host — names match hosts/<name>.nix
  # See flake.nix for the full list and hardware modules used
  <hostname> = lib.makeNixOs { ... };
  iso        = lib.makeIso  { ... };
}

homeConfigurations = {
  # Standalone home-manager (non-NixOS use)
  # Profile name defined in flake.nix
  <profile> = lib.makeHomeManagerUsers { ... };
}

packages.<system> = {
  # One deploy script per router, named openwrt-<router>
  openwrt-<router> = (openwrt (import ./openwrt-routers/<router>.nix)).deployScript;
}

devShells.<system>.default    # nix develop shell
formatter.<system>             # nixpkgs-fmt
```

---

## `lib.nix` API

```nix
lib.makeNixOs {
  hostName;                      # required — sets networking.hostName
  system        ? "x86_64-linux";
  systemStateVersion ? "26.05";
  configuration ? [];            # extra modules/files appended after main.nix
}
# Automatically includes: determinate, stylix, home-manager, nix-flatpak,
# agenix, dms (DankMaterialShell), nix-index-database, hermes-agent NixOS modules.

lib.makeIso { hostName; ... }    # same as makeNixOs + installation-cd-minimal.nix

lib.makeHomeManagerUsers {
  modules    ? [];
  userConfig ? user;             # defaults to the user attrset defined in flake.nix
  system     ? "x86_64-linux";
}

lib.makeDarwinModule {
  hostName; user;
  system        ? "x86_64-darwin";
  configuration ? [];
}

lib.eachSystem (system: ...)     # genAttrs over all systems from nix-systems/default
```

`specialArgs` injected into every host module: `unstablePkgs`, `skygUtils`, `user`,
`system`, `hyprlauncher`, `dms`, `noctalia`, `nix-index-database`, `hermes-agent`.

---

## `skyg.*` Option Namespace

All custom NixOS options. Set these in host files (`hosts/<name>.nix`).

```
skyg.user
  .name                 string   username
  .fullName             string
  .email                string
  .enable               bool     enable home-manager config for this user
  .createSystemUser     bool     create the Linux user account (default: true)
  .extraGitConfigs      list     [{path = "..."}] extra git config includes

skyg.home-manager
  .version              string   HM stateVersion (default: "26.05")
  .extraImports         list     extra HM modules to import

skyg.core
  .hostName             string   REQUIRED — sets networking.hostName
  .qemu.enable          bool     QEMU + quickemu + SPICE stack
  .substituters.urls    list     extra Nix binary cache URLs
  .substituters.keys    list     extra Nix binary cache trusted public keys

skyg.nixos.desktop
  .enable               bool     PipeWire, dbus, libinput, avahi, XDG portals, user groups
  .tiler.enable         bool     DankMaterialShell, gnome-keyring, polkit, wayland tools
  .tiler.niri.enable    bool     niri compositor; symlinks configs/niri → ~/.config/niri
  .tiler.hyprland.enable bool    Hyprland compositor
  .stylix.enable        bool     Stylix theming
  .crypto.enable        bool     crypto/wallet tools

skyg.nixos.common
  .ssh-server.enable      bool   OpenSSH, key-only auth, a master pubkey pre-authorized
  .hardware
    .sound.enable         bool
    .pipewire.enable      bool
    .amdgpu.enable        bool
    .nvidia.enable        bool
    .laptop-power-mgr.*   attrset  TLP/power management; lid switch config
    .udevrules.coraltpu.enable bool
  .containers
    .runtime              string  "docker" (default) | "podman"
    .openMetricsPort      bool    opens the container metrics port

skyg.nixos.server
  .k3s
    .enable               bool
    .role                 string  "server" (default) | "agent"
    .envPath              string  path to env file with K3s tokens/config
  .services
    .ai.enable            bool    Ollama+openwakeword containers + Wyoming whisper/piper
    .audiobookshelf.*     attrset {enable, host, port, openFirewall, configDir, metadataDir}
    .comfyui.*            attrset {enable, mode ("rocm"|"cuda"), port, rocm.dataDir}
    .dockge.*             attrset {enable, openFirewall, port, volumes.stacks/data.{nfsServer,share}}
    .jellyfin.enable      bool    NFS-backed storage
    .scrypted.enable      bool

skyg.server
  .admin.enable           bool   creates www-data group (gid=33) with user as member
  .exporters.enable       bool   Prometheus node exporter
  .timers                 attrset  {<name> = {script, OnCalendar, wantedBy}} → systemd timer+service
  .dns
    .routing.enable              bool
    .routing.openFirewall        bool
    .routing.addressesSecretName string  agenix secret name for dnsmasq address= lines
    .certbot.enable              bool
    .certbot.email               string
    .certbot.publicDomains       list

skyg.networkDrives
  .enable                 bool
  .tnas1.{enable, host}         NAS host (default defined in network-drives.nix)
  .terra1.{enable, host}        storage server host
  .bigBox2.{enable, host}       storage server host
  .options                list  NFS mount options (default: x-systemd.automount, auto, nofail, _netdev)
```

The NFS mount points provided by `skyg.networkDrives` are defined in `modules/network-drives.nix`.

---

## Hosts

See `docs/hosts/README.md` for the full per-host reference (hardware, role, services, ports).

The `flake.nix` `nixosConfigurations` block is the canonical list of managed systems.
Each host's source file is `hosts/<hostname>.nix` paired with
`hosts/<hostname>.hardware-configuration.nix`.

---

## Secrets Management

Uses [agenix](https://github.com/ryantm/agenix). All `.age` files in `secrets/` are
committed to the repo. `secrets.nix` maps each file to the SSH public keys authorized to
decrypt it — check that file for the current authorization matrix and secret list.

### Using a secret in a module

```nix
age.secrets.my-secret = {
  file = ../../secrets/my-secret.age;
};

# Reference the runtime-decrypted path (e.g. /run/agenix/my-secret).
# Never hardcode a path to the .age file itself in service config.
someOption = config.age.secrets.my-secret.path;
```

### Managing secrets

```bash
# Create or edit
agenix -e secrets/my-secret.age

# After adding a new host key to secrets.nix, re-encrypt everything:
agenix -r -i ~/.ssh/id_ed25519

# skyg wrappers
skyg secrets                   # list known secret names
skyg decrypt <name>            # → .tmp/unencrypted-<name>
skyg encrypt <name>            # ← .tmp/unencrypted-<name>
skyg compare-secret <name>     # diff plaintext vs encrypted
```

`.tmp/` is gitignored. Never commit unencrypted secrets.

### Adding a secret for a new host

```bash
ssh root@<host> "cat /etc/ssh/ssh_host_ed25519_key.pub"
# Add the key to secrets.nix, then:
agenix -r -i ~/.ssh/id_ed25519
```

---

## Binary Caches

Configured in `modules/core/nix-substituters.nix` and applied to all hosts. Includes a
local nix-serve instance on the lab network for fast rebuilds, plus several public caches.
See that file for the current URLs and trusted public keys.

---

## Dev Shell

```bash
nix develop        # or: direnv allow (if .envrc is present)
```

Provides: `nixpkgs-fmt`, `nixd`, `nh`, `agenix`, `age`, `home-manager`, `rustc`, `cargo`,
`rust-analyzer`, `nushell`

- Adds `bin/` to `PATH` → `skyg` is available immediately
- Sets `SKYG_LIB` env var for NuShell
- Enforces `nixpkgs-fmt` as a pre-commit hook on all `.nix` files
- Auto-launches NuShell with `cmds.nu` imported when running interactively

---

## Coding Conventions

- **Formatter**: `nixpkgs-fmt` — enforced by pre-commit. Run before committing.
- **Options**: Use `lib.mkEnableOption` for booleans, `lib.mkOption` with `type` and
  `description` for everything else.
- **Conditional config**: `config = lib.mkIf cfg.enable { ... }` pattern throughout.
- **Defaults**: Use `lib.mkDefault` in `main.nix` so host configs can override cleanly.
- **Unfree**: `nixpkgs.config.allowUnfree = true` is set globally — no need to repeat per-host.
- **Secrets**: Never hardcode sensitive values. Use agenix. Reference
  `config.age.secrets.<name>.path` at runtime.
- **`specialArgs`**: `unstablePkgs`, `skygUtils`, `user`, `system` are always available
  in every module — no need to pass them explicitly.
- **Nix features**: `nix-command` and `flakes` experimental features are enabled everywhere.
- **`nh`**: Preferred over raw `nixos-rebuild`. Used by both `skyg os` and `skyg remote`.

---

## Common Patterns

### Minimal server host

```nix
# hosts/<name>.nix
{ ... }: {
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.exporters.enable = true;
  skyg.networkDrives.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.fwupd.enable = true;
}
```

### Declarative systemd timer

```nix
skyg.server.timers.my-backup = {
  OnCalendar = "daily";
  wantedBy = [ "some-mount.mount" ];
  script = ''
    set -eu
    ${pkgs.rsync}/bin/rsync -av /src /dest
  '';
};
```

### Enable K3s

```nix
skyg.nixos.server.k3s = {
  enable = true;
  role = "agent";
  envPath = "/opt/k3s/k3s.env";   # file contains K3S_URL and K3S_TOKEN
};
```

### Use an agenix secret in a service

```nix
age.secrets.my-api-key.file = ../../secrets/my-api-key.age;

services.myapp.apiKeyFile = config.age.secrets.my-api-key.path;
```

### NFS-backed Dockge

```nix
skyg.nixos.server.services.dockge = {
  enable = true;
  openFirewall = true;
  volumes.stacks = { nfsServer = "<nfs-host>"; share = "/path/to/stacks"; };
  volumes.data   = { nfsServer = "<nfs-host>"; share = "/path/to/data"; };
};
```

### Desktop with tiling WM

```nix
skyg.nixos.desktop = {
  enable = true;
  tiler.enable = true;
  tiler.niri.enable = true;   # or hyprland.enable = true
  stylix.enable = true;
};
```

---

## Adding a New Host — Checklist

1. **Create host files**:
   ```
   hosts/<name>.nix
   hosts/<name>.hardware-configuration.nix   # from nixos-generate-config
   ```

2. **Register in `flake.nix`** under `nixosConfigurations`:
   ```nix
   <name> = lib.makeNixOs {
     hostName = "<name>";
     configuration = [
       ./hosts/<name>.nix
       ./hosts/<name>.hardware-configuration.nix
     ];
   };
   ```

3. **Add SSH host key to `secrets.nix`** if the host needs any secrets:
   ```bash
   ssh root@<host> "cat /etc/ssh/ssh_host_ed25519_key.pub"
   # Add the key to secrets.nix, then re-encrypt:
   agenix -r -i ~/.ssh/id_ed25519
   ```

4. **Deploy**:
   ```bash
   skyg remote switch <name>
   ```

---

## Adding a New Service Module — Checklist

1. Create `modules/nixos/server/services/<name>.nix`:
   ```nix
   { config, lib, pkgs, ... }:
   let cfg = config.skyg.nixos.server.services.<name>; in
   {
     options.skyg.nixos.server.services.<name> = {
       enable = lib.mkEnableOption "Enable <Name>";
       # add typed options here
     };
     config = lib.mkIf cfg.enable {
       # NixOS configuration goes here
     };
   }
   ```

2. Import in `modules/nixos/server/services/default.nix`:
   ```nix
   imports = [ ... ./<name>.nix ];
   ```

3. Enable on relevant hosts:
   ```nix
   skyg.nixos.server.services.<name>.enable = true;
   ```

---

## Key File Locations

| What | Path |
|------|------|
| Host registrations (canonical list) | `flake.nix` → `nixosConfigurations` |
| Secret authorization map | `secrets.nix` |
| User / global config (name, email, etc.) | `flake.nix` → `lib =` binding |
| Base module every host receives | `modules/main.nix` |
| Home Manager programs | `modules/home/programs.nix` |
| Binary cache configuration | `modules/core/nix-substituters.nix` |
| SSH master public key | `modules/nixos/common/ssh-server.nix` |
| All `skyg` subcommand implementations | `bin/lib/cmds.nu` |
| Valid remote deployment targets | `bin/lib/profile.nu` |
| Router configs | `openwrt-routers/` |
| Desktop compositor configs | `configs/` |
| Full host documentation | `docs/hosts/README.md` |
| Module architecture + option reference | `docs/modules/README.md` |
| Secrets workflow | `docs/secrets/README.md` |
