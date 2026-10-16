# NixOS System Configurations

Nix configs for all my machines: local desktops/laptops and homelab servers.

## Repository Layout

```
nixos-setup/
├── bin/                  # `skyg` CLI (see bin/ABOUTME.md)
│   ├── skyg              # Bash shim → NuShell modules in bin/lib/
│   ├── temp-monitor      # CPU/GPU temperature logger (see TEMP_MONITOR_README.md)
│   └── lib/              # Command modules: os, remote, secrets, ca, pkgs, flake, build, render, hm, net
├── configs/              # App configs per host, plus configs/pki (lab TLS certs)
├── pkgs/                 # Custom packages (see pkgs/ABOUTME.md)
├── hosts/                # One folder per host (fwbook, hl-*, iso) + disko/hardware files
├── modules/
│   ├── main.nix          # Entry point that wires all modules together
│   ├── core/             # Core system modules
│   ├── nixos/            # NixOS modules (desktop, server, common)
│   ├── home/             # Home Manager modules
│   ├── openwrt/          # OpenWrt config generator
│   └── *.nix             # Shared helpers (lib, skyg-utils, internal-networking, …)
├── openwrt-routers/      # OpenWrt router configs (glmain)
├── secrets/              # agenix-encrypted secrets (keys listed in secrets.nix)
├── docs/                 # Documentation
└── flake.nix             # Flake definition
```

## Using This Flake

Custom packages and helpers are exported for reuse:

```nix
{
  inputs.nixos-setup.url = "github:skykanin/nixos-setup";

  outputs = { nixos-setup, ... }:
    let
      pkgs = nixos-setup.lib.pkgs."x86_64-linux";
    in {
      environment.systemPackages = [ pkgs.niri-touchscreen-gestures ];
    };
}
```

`nixos-setup.lib` also provides `makeNixOs`, `makeHomeManagerUsers`, `makeIso`, `makeSdImage`, and more.

Inside this repo, every package in `pkgs/` is available as `pkgs.<name>` through the overlay.

## The `skyg` CLI

`bin/skyg` is the main tool for this repo. Run `skyg` to list subcommands, or `skyg <subcommand> --help` for details.

### Local system — `skyg os`

| Command                                | Description                                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| `skyg os <action>`                     | Rebuild locally. Actions: `test`, `dry-activate`, `run`, `switch`, `build`, `boot` |
| `skyg os <action> --build-host <host>` | Build on another machine (e.g. `--build-host fwdesk`)                              |
| `skyg os rollback`                     | Go back to the previous generation                                                 |

### Remote hosts — `skyg remote`

| Command                         | Description                                                                                                                                                                       |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skyg remote <action> <target>` | Deploy to a remote host. Same actions as `skyg os`                                                                                                                                |
| `skyg remote install <target>`  | Fresh install via nixos-anywhere using `hosts/hl-<target>.disko.nix`. **Wipes disks.** Asks you to type the hostname; refuses if NixOS is already installed unless `--force-wipe` |
| `skyg remote status <target>`   | Show one host's status                                                                                                                                                            |
| `skyg remote status --all`      | Show all hosts: generation, pending reboot, needs rebuild                                                                                                                         |
| `skyg remote boot-all`          | Run `boot` on every online remote (skips this machine)                                                                                                                            |
| `skyg remote reboot-pending`    | Reboot hosts whose booted system differs from the current one, one at a time, after confirmation                                                                                  |

Example: `skyg remote switch bigbox1` deploys `hl-bigbox1` to `root@bigbox1.lab.internal`.

### Flake — `skyg flake`

| Command                     | Description                                                |
| --------------------------- | ---------------------------------------------------------- |
| `skyg flake update [input]` | Update all inputs, or one, then show the `flake.lock` diff |
| `skyg flake check`          | Run `nix flake check --no-build`                           |
| `skyg flake check-versions` | Check that all inputs use the same NixOS release           |

### Images and routers — `skyg build`

| Command                                   | Description                                                                    |
| ----------------------------------------- | ------------------------------------------------------------------------------ |
| `skyg build image <iso\|pi1\|pi2>`        | Build an ISO or a Pi SD card image                                             |
| `skyg build openwrt [router] [--dry-run]` | Deploy a router config (default `glmain`). `--dry-run` only renders to `.tmp/` |

### Home Manager — `skyg hm`

| Command                    | Description                               |
| -------------------------- | ----------------------------------------- |
| `skyg hm switch [profile]` | Apply Home Manager config (default `ari`) |
| `skyg hm build [profile]`  | Build Home Manager config                 |

### Secrets — `skyg secrets`

| Command                                      | Description                                     |
| -------------------------------------------- | ----------------------------------------------- |
| `skyg secrets` / `skyg secrets list`         | List secret names                               |
| `skyg secrets show <secret>`                 | Decrypt to `.tmp/unencrypted-<secret>`          |
| `skyg secrets edit <secret> [file] [--yaml]` | Edit and re-encrypt (`--yaml` validates first)  |
| `skyg secrets compare <secret>`              | Diff the working copy against the stored secret |

### Lab CA — `skyg ca`

| Command                               | Description                                                                             |
| ------------------------------------- | --------------------------------------------------------------------------------------- |
| `skyg ca init`                        | Create the root CA: key → `secrets/lab-ca-key.age`, cert → `configs/pki/lab-ca.crt`     |
| `skyg ca issue <domain> --for <host>` | Issue a TLS cert: cert → `configs/pki/<domain>.crt`, key → `secrets/<name>-tls-key.age` |

### Custom packages — `skyg pkgs`

| Command                            | Description                                     |
| ---------------------------------- | ----------------------------------------------- |
| `skyg pkgs update --all`           | Update every package that has an `update.sh`    |
| `skyg pkgs update <pkg> [version]` | Update one package (latest, or a given version) |

### Network — `skyg net`

| Command                   | Description                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| `skyg net check [device]` | Show NIC info and run a speed test on every device (or one). `--no-speedtest` skips the test |
| `skyg net last`           | Show the results of the last `skyg net check`                                                |

### Other

| Command                       | Description                                             |
| ----------------------------- | ------------------------------------------------------- |
| `skyg profiles`               | List all profiles                                       |
| `skyg profiles true`          | List only remote (`hl-*`) profiles                      |
| `skyg render html-tpl <file>` | Preview a Gitea `.tmpl` on `127.0.0.1` (Ctrl+C to stop) |

## Managing Secrets

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix) and stored in `secrets/`.

To give a new host access:

1. Get its key: `cat /etc/ssh/ssh_host_ed25519_key.pub`
2. Add it to `secrets.nix` and to each secret's `publicKeys`
3. Re-encrypt each affected secret: `skyg secrets show <name>`, then `skyg secrets edit <name>`

See `secrets/ABOUTME.md` and `docs/agenix.md` for more.

## Host Profiles

- **Local**: `fwbook` (Framework laptop)
- **Remote**: `hl-bigbox1`, `hl-bigbox2`, `hl-fwdesk`, `hl-fws1`, `hl-minipc1`, `hl-minipc2`, `hl-minipc3`, `hl-pi1`, `hl-pi2`, `hl-terra1`
- **ISO**: `iso` (bootable installer)

See `docs/hosts/README.md` for per-host details.
