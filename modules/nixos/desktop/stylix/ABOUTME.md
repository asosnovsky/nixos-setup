# modules/nixos/desktop/stylix/

System theming through [Stylix](https://github.com/danth/stylix): one base16 scheme and
font set for the system-level targets (console, boot, fonts, Qt platform theme).

Stylix's per-user themes needed Home Manager, which this repo no longer uses. The GTK and
Qt app themes are instead a fixed copy of what Stylix generated for `gruvbox-dark-hard`,
kept in `configs/shared/theme/` and linked read-only into the home dir.

## Files

```
stylix/
└── default.nix   # skyg.nixos.desktop.stylix.enable (default true)
```

## Behaviour

- Defaults to **enabled**, but only takes effect when `skyg.nixos.desktop.enable` is also set.
- Scheme: `gruvbox-dark-hard`, dark polarity, `autoEnable = true`.
- Fonts: DejaVu (serif/sans/mono) + Noto Color Emoji.
- Installs `adw-gtk3` and sets dark mode + `adw-gtk3` as dconf defaults.
- On hosts with `skyg.user.enable`, links `configs/shared/theme/` into `~/.gtkrc-2.0`,
  `~/.config/gtk-{3,4}.0/`, `~/.config/Kvantum/` and `~/.config/qt{5,6}ct/`.

## Option Namespace

```
skyg.nixos.desktop.stylix.enable   # default true; gated on desktop.enable
```

## Conventions

- Changing `base16Scheme` here does **not** update the GTK/Qt files in
  `configs/shared/theme/`; edit those by hand to match.
- Disable via `skyg.nixos.desktop.stylix.enable = false` on hosts that want manual theming.
