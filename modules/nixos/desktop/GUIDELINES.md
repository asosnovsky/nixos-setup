# Guidelines — modules/nixos/desktop/

Conventions for the desktop/workstation tree. Read alongside the repo-root `GUIDELINES.md`.

---

## Everything hangs off the master switch

`skyg.nixos.desktop.enable` is the gate for the whole tree. New desktop modules must not
activate unless it (or their own sub-option) is set:

```nix
let cfg = config.skyg.nixos.desktop; in {
  config = lib.mkIf cfg.enable { ... };
}
```

Sub-features (a DE, a tiler, crypto wallets, gestures) get their **own** `enable` option so a
host opts into exactly the stack it wants.

## Greeter / login — do not hand-roll

Desktop/tiler hosts use **DankMaterialShell (DMS)** for the greeter, configured via
`programs.dank-material-shell` (see `tiler/default.nix` and the repo-root `GUIDELINES.md`).

- Do **not** configure `services.greetd` manually on these hosts.
- The keyring (`gnome-keyring`) provides the SSH agent on tiler hosts, so
  `programs.ssh.startAgent` stays **off**. Don't re-enable it.

## Tilers

- Enable a compositor (`skyg.nixos.desktop.tiler.niri` or `…tiler.hyprland`), which flips the
  shared `tiler.enable` for you. Don't set `tiler.enable` directly.
- Shared Wayland tooling, keyring, and polkit live in `tiler/default.nix` — add anything
  common to _all_ tilers there, not in the individual compositor files.

## Theming

- Global theming is **Stylix** (`stylix/`), enabled by default and gated on `desktop.enable`.
- Change the look in `stylix/default.nix` (base16 scheme + fonts). Avoid scattering per-app
  color overrides elsewhere; let Stylix drive it.

## Config symlinks

Some modules symlink files from the repo's `configs/` directory into the home dir via
activation scripts. Edit the file in
`configs/`, not the module, when changing that behaviour. For new links use
`skyg.configLinks.links` (see `modules/nixos/common/ABOUTME.md`).

## Validation

Do **not** build or switch. `nix-instantiate --parse` is the only safe local check; the user
validates on real hardware.
