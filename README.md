# NixOS System Configurations

My comprehensive Nix configurations for managing multiple hosts, including local machines and remote servers.

## Repository Layout

```
nixos-setup/
├── bin/                  # `skyg` CLI
│   ├── skyg              # Bash shim → NuShell command modules in bin/lib/
│   ├── check-flake-versions  # Shim for `skyg flake check-versions`
│   ├── temp-monitor      # NuShell CPU/GPU temperature logger (see TEMP_MONITOR_README.md)
│   └── lib/              # NuShell command modules (os, remote, secrets, ca, pkgs, flake, build, render, hm)
├── configs/              # Application-specific configurations (incl. configs/pki TLS certs)
├── pkgs/                 # Custom packages (buzz-desktop, colibri, delta-editor, niri-touchscreen-gestures, superset-desktop)
├── hosts/                # One folder per host (fwbook, hl-*, iso) + generated hardware configs
├── modules/              # Reusable NixOS and Home Manager modules
│   ├── core/             # Core system modules
│   ├── home/             # Home Manager modules
│   ├── nixos/            # NixOS-specific modules
│   └── *.nix             # Utility modules (lib, skyg-utils, internal-networking, etc.)
├── openwrt-routers/      # OpenWrt router configs (glmain)
├── docs/                 # Documentation
├── flake.nix             # Nix flake definition
├── flake.lock            # Locked dependency versions
└── README.md             # This file
```

## Using This Flake

To use the custom packages in your own NixOS/Home Manager configuration:

```nix
{
  inputs.nixos-setup.url = "github:skykanin/nixos-setup";

  outputs = { self, nixpkgs, nixos-setup, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixos-setup.lib.pkgs.${system};
    in {
      environment.systemPackages = with pkgs; [
        niri-touchscreen-gestures
      ];
    };
}
```

You can also import `nixos-setup.lib` to reuse `makeNixOs`, `makeHomeManagerUsers`, `makeIso`, `makeSdImage`, and other utilities.

See [`pkgs/ABOUTME.md`](pkgs/ABOUTME.md) for details on each package.

## Quick Start

The `skyg` script is your main interface for managing these configurations. It's located in `bin/skyg` and uses NuShell. Run `skyg` with no arguments to list subcommands, or `skyg <subcommand> --help` for details.

### Available Commands

#### Local System (`skyg os`)

- **`skyg os <action>`** - Run a local NixOS rebuild. Actions: `test`, `dry-activate`, `run`, `switch`, `build`, `boot`
- **`skyg os rollback`** - Roll back to the previous generation
- **`--build-host <host>`** - Build on a remote builder (e.g. `skyg os switch --build-host fwdesk`)

#### Remote Deployments (`skyg remote`)

- **`skyg remote <command> <target>`** - Deploy to a remote machine

Supported remote commands: `test`, `dry-activate`, `run`, `switch`, `build`, `boot`

Example: `skyg remote switch bigbox1` deploys using the `hl-bigbox1` profile to `root@bigbox1.lab.internal`

- **`skyg remote install <target>`** - Fresh-install a remote host via nixos-anywhere, using `hosts/hl-<target>.disko.nix`. Always wipes the disks in that file. Aborts if the disko file is missing, if the host already boots NixOS from disk (unless `--force-wipe`), or if you don't type the short hostname to confirm.
- **`skyg remote status <target>`** - Check status of a single remote host
- **`skyg remote status --all`** - Check status of all remote hosts (generation, pending reboot, needs rebuild)
- **`skyg remote boot-all`** - Boot all remote hosts (skips the current machine, checks online status first)
- **`skyg remote reboot-pending`** - Find every remote with a pending reboot (its booted system differs from its current system) and reboot them. Lists the affected hosts and asks for confirmation, then reboots them one at a time, waiting for each to come back online and sending a desktop notification when it does.

#### Flake Management (`skyg flake`)

- **`skyg flake update [input]`** - Update all flakes, or a specific input (e.g. `skyg flake update nixpkgs`). Displays the diff of `flake.lock` after updating.
- **`skyg flake check`** - Run `nix flake check --no-build`
- **`skyg flake check-versions`** - Verify NixOS release version consistency across flake inputs

#### Building Images and Routers (`skyg build`)

- **`skyg build image <iso|pi1|pi2>`** - Build a bootable image: ISO (`iso`) or Pi SD card image (`pi1`, `pi2`)
- **`skyg build openwrt [router]`** - Deploy an OpenWrt router config (default: `glmain`). Add `--dry-run` to render configs to `.tmp/` without touching the router.

#### Home Manager (`skyg hm`)

- **`skyg hm switch [profile]`** - Apply home-manager configuration (default: `ari`)
- **`skyg hm build [profile]`** - Build home-manager configuration

Example: `skyg hm switch ari` or `skyg hm switch`

#### Secrets (`skyg secrets`)

- **`skyg secrets list`** - List known secret names
- **`skyg secrets show <secret>`** - Decrypt a secret to `.tmp/unencrypted-<secret>`
- **`skyg secrets edit <secret> [--yaml]`** - Encrypt a working copy back into the secret
- **`skyg secrets compare <secret>`** - Diff the working copy against the stored secret

#### Lab CA (`skyg ca`)

- **`skyg ca init`** - Generate the lab root CA: key → `secrets/lab-ca-key.age`, cert → `configs/pki/lab-ca.crt`
- **`skyg ca issue <domain> --for <host>`** - Mint a TLS leaf cert signed by the lab CA: cert → `configs/pki/<domain>.crt`, key → `secrets/<name>-tls-key.age`

#### Custom Packages (`skyg pkgs`)

- **`skyg pkgs update --all`** - Auto-detect the latest version for all packages that have `update.sh`
- **`skyg pkgs update <pkg>`** - Auto-detect the latest version for a single package
- **`skyg pkgs update <pkg> <version>`** - Bump a package to an explicit version

#### Other

- **`skyg profiles`** - List all available local profiles
- **`skyg profiles --only_remote`** - List only remote profiles (prefixed with `hl-`)
- **`skyg render html-tpl <file>`** - Render a Gitea `.tmpl` and serve it on `127.0.0.1` for preview. Foreground — Ctrl+C to stop.

## Usage Examples

```bash
# Check available profiles
skyg profiles

# Build and switch to new configuration
skyg os build
skyg os switch

# Test configuration before switching
skyg os test

# Update dependencies
skyg flake update nixpkgs

# Deploy to a remote server
skyg remote switch bigbox1

# Rollback if something goes wrong
skyg os rollback

# Apply home-manager changes
skyg hm switch
```

### Using Custom Packages

All packages from `pkgs/` are available in your configuration as `pkgs.<name>` thanks to the overlay.

Example:

```nix
environment.systemPackages = with pkgs; [ niri-touchscreen-gestures ];
```

See [`pkgs/ABOUTME.md`](pkgs/ABOUTME.md) for details on each package.

## Managing Secrets

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix) and stored in `secrets/`.

### Adding a Host to Secrets

1. **Get the host's SSH public key**: `cat /etc/ssh/ssh_host_ed25519_key.pub`
2. **Add to `secrets.nix`**: Create a variable with the key and add it to each secret's `publicKeys` list
3. **Re-encrypt**: for each affected secret run `skyg secrets show <name>` then `skyg secrets edit <name>` to re-encrypt it against the updated key set

For more details, see `secrets/ABOUTME.md`.

## Host Profiles

Available profiles include:

- **Local**: `fwbook` (Framework laptop)
- **Remote**: `hl-bigbox1`, `hl-bigbox2`, `hl-fwdesk`, `hl-fws1`, `hl-minipc1`, `hl-minipc2`, `hl-minipc3`, `hl-pi1`, `hl-pi2`, `hl-terra1`
- **ISO**: `iso` (bootable image)

All profiles automatically have access to the custom packages from the `pkgs/` directory.
