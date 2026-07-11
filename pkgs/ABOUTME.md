# pkgs/

Custom Nix package derivations for software not available in nixpkgs (or needing local overrides).
Packages here are exposed via an overlay defined in `modules/core/default.nix`.

## Contents

| Package | Description |
|---|---|
| `grok-cli/` | xAI Grok CLI — prebuilt static binary, fetched per-platform. Exposed as `pkgs.grok-cli`. |
| `ds4/` | DwarfStar (`antirez/ds4`) DeepSeek V4 local inference engine, built from source. Backend-parameterized (`backend = "cpu" \| "rocm" \| "cuda"`); tracks `main` and builds per-host. Exposed as `pkgs.ds4` (cpu, default), `pkgs.ds4-rocm` (Strix Halo / gfx1151), `pkgs.ds4-cuda`. Installs the `ds4`, `ds4-server`, `ds4-bench`, `ds4-eval`, `ds4-agent` binaries plus a `ds4-download-model` helper for fetching GGUF weights. Model weights are a runtime concern and not packaged. |
| `niri-touchscreen-gestures/` | Python daemon that reads multi-touch events from a touchscreen via `evdev`, detects 2/3/4-finger swipes (up/down/left/right), and dispatches configurable `niri msg action` commands. Configured via TOML; exposed as `pkgs.niri-touchscreen-gestures`. |

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

## Notes

- For unfree or binary packages, set `meta.license` and `meta.sourceProvenance` accurately
- Use `stdenvNoCC` for prebuilt binaries that don't need compilation
- Hash updates: use `nix hash file --type sha256 --sri <file>` after downloading the new binary
