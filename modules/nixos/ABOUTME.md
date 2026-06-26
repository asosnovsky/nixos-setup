# modules/nixos/

All Linux/NixOS-specific modules, grouped by scope. `default.nix` simply imports the three
subtrees below; every option here lives under `skyg.nixos.*` (with a few legacy
`skyg.server.*` and `skyg.core.*` exceptions noted in the subfolders).

## Structure

```
nixos/
├── default.nix   # imports common/ + server/ + desktop/
├── common/        # Settings every Linux host gets (core, networking, ssh, fonts, hardware…)
├── server/        # Opt-in server roles & services (K3s/K8s, ARRs, DNS, AI, media…)
└── desktop/       # Opt-in desktop: tilers, theming, browsers, crypto wallets, printers…
```

## How it composes

- `common/` is always active (it sets base system options directly, gated only per-feature).
- `server/` and `desktop/` are large opt-in trees. Most leaf modules do nothing until their
  `enable` option is set, so importing the whole tree is cheap.
- The two top-level gates are `skyg.nixos.desktop.enable` and the per-service enables under
  `skyg.nixos.server.*` / `skyg.server.*`.

## Option Namespace

```
skyg.nixos.common.*    → common/
skyg.nixos.desktop.*   → desktop/
skyg.nixos.server.*    → server/   (most services)
skyg.server.*          → server/   (arrs, admin, exporters, timers, dns — legacy prefix)
skyg.core.qemu.*       → common/qemu.nix
```

## Conventions

- New shared Linux behaviour goes in `common/`; opt-in roles go in `server/` or `desktop/`.
- Gate everything behind an `enable` option with `lib.mkIf cfg.enable { ... }`.
- Note the naming split: newer server modules use `skyg.nixos.server.*` while several older
  ones use `skyg.server.*`. Match the surrounding file when extending.
