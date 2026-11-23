# modules/core/

Base configuration imported by **every** host via
`modules/main.nix`. This is where the primary user, Nix binary caches, distributed builds,
and a couple of nixpkgs overlays/workarounds live.

## Files

```
core/
├── default.nix          # Entry point: imports the files below + overlays + remote builder
├── user.nix             # skyg.user.* — options for the main user
├── nix-substituters.nix # skyg.core.substituters.* — binary caches & trusted keys
└── lab-ca.nix           # Fleet-wide trust of the lab internal CA (configs/pki/lab-ca.crt)
```

## What lives here

- **Overlays** (`default.nix`): exposes the `pkgs/` packages — `grok-cli`, `colibri` (+`colibri-rocm`), `niri-touchscreen-gestures`,
  `buzz-desktop`, — and patches `python3Packages.pipx` to skip its flaky install check on nixpkgs 26.05.
- **Distributed builds** (`default.nix`): registers `bigbox1.lab.internal` and
  `fwdesk.lab.internal` as remote `x86_64-linux` build machines and enables
  `builders-use-substitutes`.
- **User** (`user.nix`): defines `skyg.user.{enable,name,fullName,email,extraGitConfigs}`.
  It only declares the options; `skyg.user.enable` is applied by
  `nixos/common/user-env/` (shell and CLI setup for the user and root).
- **Substituters** (`nix-substituters.nix`): the standing list of caches (local `minipc1`
  and `bigbox2` caches, cache.nixos.org, cachix caches for cuda/ai/noctalia/hyprland/nixarchy,
  flox, devenv) and the trusted public keys. Extra entries can be appended per-host via
  `skyg.core.substituters.{urls,keys}`. Also sets `http-connections = 8` and
  `download-attempts = 10` so flaky links (Wi-Fi) don't disable cache.nixos.org mid-build.
- **Lab CA trust** (`lab-ca.nix`): adds `configs/pki/lab-ca.crt` to
  `security.pki.certificateFiles` so every machine trusts the lab internal CA
  (created by `skyg ca init`, see `configs/pki/ABOUTME.md`). Eval fails if the
  cert file is missing — run `skyg ca init` before the first rebuild.

## Option Namespace

```
skyg.user.*                  → user.nix
skyg.core.substituters.*     → nix-substituters.nix
```

## Conventions

- `skyg.user.enable` turns on the shell setup and asserts that `name`, `fullName`, and
  `email` are non-empty.
- Cache URLs/keys here are global defaults; add host-specific caches through the
  `skyg.core.substituters.{urls,keys}` options rather than editing this file.
