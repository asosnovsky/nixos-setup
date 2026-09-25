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
├── lab-ca.nix           # Fleet-wide trust of the lab internal CA (configs/pki/lab-ca.crt)
└── macos.nix            # skyg.user.macos.enableOverride — macOS-only HM tweaks
```

## What lives here

- **Overlays** (`default.nix`): exposes the `pkgs/` packages — `grok-cli`, `colibri` (+`colibri-rocm`), `niri-touchscreen-gestures`,
  `buzz-desktop`, — and patches `python3Packages.pipx` to skip its flaky install check on nixpkgs 26.05.
- **Distributed builds** (`default.nix`): registers `bigbox1.lab.internal` and
  `fwdesk.lab.internal` as remote `x86_64-linux` build machines and enables
  `builders-use-substitutes`.
- **User** (`user.nix`): defines `skyg.user.{name,fullName,email}` plus
  `skyg.home-manager.{version,extraImports}`. When `skyg.user.enable` is set it wires up
  Home Manager for both `root` and the named user using the functions in `modules/home`.
- **Substituters** (`nix-substituters.nix`): the standing list of caches (local `minipc1`
  and `bigbox2` caches, cache.nixos.org, cachix caches for cuda/cosmic/ai/noctalia, flox,
  devenv) and the trusted public keys. Extra entries can be appended per-host via
  `skyg.core.substituters.{urls,keys}`.
- **Lab CA trust** (`lab-ca.nix`): adds `configs/pki/lab-ca.crt` to
  `security.pki.certificateFiles` so every machine trusts the lab internal CA
  (created by `skyg ca init`, see `configs/pki/ABOUTME.md`). Eval fails if the
  cert file is missing — run `skyg ca init` before the first rebuild.

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
