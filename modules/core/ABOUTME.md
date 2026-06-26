# modules/core/

Cross-platform base configuration imported by **every** host (NixOS and macOS) via
`modules/main.nix`. This is where the primary user, Nix binary caches, distributed builds,
and a couple of nixpkgs overlays/workarounds live.

## Files

```
core/
├── default.nix          # Entry point: imports the files below + overlays + remote builder
├── user.nix             # skyg.user.* — the human user + Home Manager wiring
├── nix-substituters.nix # skyg.core.substituters.* — binary caches & trusted keys
└── macos.nix            # skyg.user.macos.enableOverride — macOS-only HM tweaks
```

## What lives here

- **Overlays** (`default.nix`): exposes `pkgs.grok-cli` (from `pkgs/grok-cli`) and patches
  `python3Packages.pipx` to skip its flaky install check on nixpkgs 26.05.
- **Distributed builds** (`default.nix`): registers `bigbox1.lab.internal` as a remote
  `x86_64-linux` build machine and enables `builders-use-substitutes`.
- **User** (`user.nix`): defines `skyg.user.{name,fullName,email}` plus
  `skyg.home-manager.{version,extraImports}`. When `skyg.user.enable` is set it wires up
  Home Manager for both `root` and the named user using the functions in `modules/home`.
- **Substituters** (`nix-substituters.nix`): the standing list of caches (local `minipc1`
  cache, cache.nixos.org, cachix caches for cuda/cosmic/ai/noctalia, flox, devenv) and the
  trusted public keys. Extra entries can be appended per-host via `skyg.core.substituters.{urls,keys}`.

## Option Namespace

```
skyg.user.*                  → user.nix (+ macos.nix for the macOS override)
skyg.home-manager.*          → user.nix
skyg.core.substituters.*     → nix-substituters.nix
```

## Conventions

- `skyg.user.enable` triggers Home Manager setup and asserts that `name`, `fullName`, and
  `email` are non-empty.
- Cache URLs/keys here are global defaults; add host-specific caches through the
  `skyg.core.substituters.{urls,keys}` options rather than editing this file.
