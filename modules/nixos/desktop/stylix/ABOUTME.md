# modules/nixos/desktop/stylix/

System-wide theming through [Stylix](https://github.com/danth/stylix). Applies a single
base16 scheme and font set across the desktop (GTK, Qt, terminals, etc.) automatically.

## Files

```
stylix/
└── default.nix   # skyg.nixos.desktop.stylix.enable (default true)
```

## Behaviour

- Defaults to **enabled**, but only takes effect when `skyg.nixos.desktop.enable` is also set.
- Scheme: `gruvbox-dark-hard`, dark polarity, `autoEnable = true`.
- Fonts: DejaVu (serif/sans/mono) + Noto Color Emoji.

## Option Namespace

```
skyg.nixos.desktop.stylix.enable   # default true; gated on desktop.enable
```

## Conventions

- To change the global theme, edit the `base16Scheme`/`fonts` here rather than overriding
  per-app theming downstream.
- Disable via `skyg.nixos.desktop.stylix.enable = false` on hosts that want manual theming.
