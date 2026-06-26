# NixOS System Configurations

My comprehensive Nix configurations for managing multiple hosts, including local machines and remote servers.

## Repository Layout

```
nixos-setup/
├── bin/
│   └── skyg              # Main CLI tool for managing NixOS configurations
├── configs/              # Application-specific configurations
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
