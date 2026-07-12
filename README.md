# NixOS System Configurations

My comprehensive Nix configurations for managing multiple hosts, including local machines and remote servers.

## Repository Layout

```
nixos-setup/
├── bin/
│   └── skyg              # Main CLI tool for managing NixOS configurations
├── configs/              # Application-specific configurations
├── pkgs/                 # Custom packages (niri-touchscreen-gestures, grok-cli, ds4)
├── hosts/                # Host-specific NixOS configurations
│   ├── *.nix             # Host configuration files (fwbook, hl-bigbox1, hl-minipc*, etc.)
│   ├── *.hardware-configuration.nix  # Hardware-specific configurations
│   └── scripts/          # Host-specific scripts
├── modules/              # Reusable NixOS and Home Manager modules
│   ├── core/             # Core system modules
│   ├── home/             # Home Manager modules
│   ├── nixos/            # NixOS-specific modules
│   └── *.nix             # Utility modules (lib, skyg-utils, network-drives, etc.)
├── apps/                 # Standalone applications
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
        grok-cli
        ds4
      ];
    };
}
```

You can also import `nixos-setup.lib` to reuse `makeNixOs`, `makeHomeManagerUsers`, and other utilities.

See [`pkgs/ABOUTME.md`](pkgs/ABOUTME.md) for details on each package.

**Key packages:** `niri-touchscreen-gestures` (run `niri-touchscreen-gestures` — uses built-in defaults), `grok-cli`, and `ds4` (local LLM inference with CPU/ROCm/CUDA support).

## Quick Start

The `skyg` script is your main interface for managing these configurations. It's located in `bin/skyg` and uses NuShell.

### Available Commands

#### System Management

- **`skyg build`** - Build the current system configuration
- **`skyg switch`** - Switch to a new configuration (with confirmation)
- **`skyg test`** - Test a configuration without switching
- **`skyg rollback`** - Rollback to the previous generation

#### Profile Management

- **`skyg profiles`** - List all available local profiles
- **`skyg profiles --only_remote`** - List only remote profiles (prefixed with `hl-`)

#### Flake Updates

- **`skyg update`** - Update all flakes to their latest versions
- **`skyg update <flake_name>`** - Update a specific flake (e.g., `skyg update nixpkgs`)

Displays the diff of `flake.lock` after updating.

#### Remote Deployments

- **`skyg remote <command> <target>`** - Deploy to a remote machine

Supported remote commands: `test`, `dry-activate`, `run`, `switch`, `build`

Example: `skyg remote switch bigbox1` deploys using the `hl-bigbox1` profile to `root@bigbox1.lab.internal`

#### Home Manager

- **`skyg hm switch [profile]`** - Apply home-manager configuration (default: `ari`)
- **`skyg hm build [profile]`** - Build home-manager configuration

Example: `skyg hm switch ari` or `skyg hm switch`

#### ISO Images

- **`skyg build-iso`** - Build a bootable ISO image

## Usage Examples

```bash
# Check available profiles
skyg profiles

# Build and switch to new configuration
skyg build
skyg switch

# Test configuration before switching
skyg test

# Update dependencies
skyg update nixpkgs

# Deploy to a remote server
skyg remote switch bigbox1

# Rollback if something goes wrong
skyg rollback

# Apply home-manager changes
skyg hm switch
```

### Using Custom Packages

All packages from `pkgs/` are available in your configuration as `pkgs.<name>` thanks to the overlay.

Example:

```nix
environment.systemPackages = with pkgs; [ niri-touchscreen-gestures grok-cli ds4 ];
```

See [`pkgs/ABOUTME.md`](pkgs/ABOUTME.md) for details on each package.

## Managing Secrets

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix) and stored in `secrets/`.

### Adding a Host to Secrets

1. **Get the host's SSH public key**: `cat /etc/ssh/ssh_host_ed25519_key.pub`
2. **Add to `secrets.nix`**: Create a variable with the key and add it to each secret's `publicKeys` list
3. **Re-key**: Run `skyg secrets rekey` to re-encrypt the `.age` files

For more details, see `secrets/ABOUTME.md`.

## Host Profiles

Available profiles include:
- **Local**: `fwbook` (Framework laptop)
- **Remote**: `hl-bigbox1`, `hl-bigbox2`, `hl-fwdesk`, `hl-fws1`, `hl-minipc1`, `hl-minipc2`, `hl-minipc3`, `hl-terra1`
- **ISO**: `iso` (bootable image)

All profiles automatically have access to the custom packages from the `pkgs/` directory.
