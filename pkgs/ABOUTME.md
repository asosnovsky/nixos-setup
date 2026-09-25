# pkgs/

Custom Nix package derivations for software not available in nixpkgs (or needing local overrides).
Packages here are exposed via an overlay defined in `modules/core/default.nix`.

## Contents

| Package                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `colibri/`                   | colibrì (`JustVugg/colibri`) — GLM-5.2/OLMoE local inference engine, built from source, pinned to a tagged release. Backend-parameterized (`backend = "cpu" \| "rocm"`). Exposed as `pkgs.colibri` (cpu, default), `pkgs.colibri-rocm` (Strix Halo / gfx1151). Installs the `coli` CLI (wrapped with the Python env its converter/bench subcommands need) plus the bundled `colibri`/`olmoe` engine binaries. Model weights are a runtime concern and not packaged.                    |
| `niri-touchscreen-gestures/` | Python daemon that reads multi-touch events from a touchscreen via `evdev`, detects 2/3/4-finger swipes (up/down/left/right), and dispatches configurable `niri msg action` commands. Configured via TOML; exposed as `pkgs.niri-touchscreen-gestures`.                                                                                                                                                                                                                                |
| `buzz-desktop/`              | Block Buzz desktop (Type-2 AppImage from `block/buzz`). Wrapped with `appimageTools.wrapType2` plus extra FHS libs (`elfutils`, `zstd`, WebKit/tray, GStreamer good/bad) so it runs on NixOS. Exposed as `pkgs.buzz-desktop` (`buzz-desktop` binary + desktop entry / icons).                                                                                                                                                                                                          |
| `superset-desktop/`          | Superset Desktop (Type-2 AppImage from `superset-sh/superset`). Wrapped with `appimageTools.wrapType2` plus extra FHS libs (`elfutils`, `zstd`, WebKit/tray, GStreamer good/bad) so it runs on NixOS. Exposed as `pkgs.superset-desktop` (`superset-desktop` binary + desktop entry / icons).                                                                                                                                                                                          |
| `delta/`                     | Delta (Zed Industries' AI-native editor, `delta.dev`) prebuilt tarball. No stable URL exists — the release API returns a short-lived signed R2 link — so `src` is a fixed-output derivation that resolves the API at build time. Interpreter/RPATH patched (`--force-rpath`), dlopen'd graphics libs (`libglvnd`, `vulkan-loader`, `wayland`) added via wrapper, `XKB_CONFIG_ROOT` set for the bundled libxkbcommon. Exposed as `pkgs.delta` (`delta` binary + desktop entry / icons). |

## Adding a New Package

1. Create `pkgs/<name>/default.nix` with a standard derivation
2. Add an entry to the overlay in `modules/core/default.nix`:
   ```nix
   (final: _prev: {
     <name> = final.callPackage ../../pkgs/<name> { };
   })
   ```
3. Reference it as `pkgs.<name>` anywhere in the flake
4. Optionally expose it as a flake output in `flake.nix` under `packages`

## Updating Packages

Each package can have an `update.sh` script that automates version bumps.

- **`skyg pkgs bump <pkg-name> <version>`** — bump a specific package to a specific version.
- **`skyg pkgs update --all`** — auto-detect the latest version for all packages that have `update.sh`.
- **`skyg pkgs update <pkg-name>`** — auto-detect the latest version for a single package.

Each `update.sh` supports two modes:

- `./update.sh <version>` — bump to the given version.
- `./update.sh` (no args) — auto-detect the latest version from upstream.

## Notes

- For unfree or binary packages, set `meta.license` and `meta.sourceProvenance` accurately
- Use `stdenvNoCC` for prebuilt binaries that don't need compilation
- Hash updates: use `nix hash file --type sha256 --sri <file>` after downloading the new binary
