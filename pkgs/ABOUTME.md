# pkgs/

Custom Nix package derivations for software not available in nixpkgs (or needing local overrides).
Packages here are exposed via an overlay defined in `modules/core/default.nix`.

## Contents

| Package | Description |
|---|---|
| `grok-cli/` | xAI Grok CLI — prebuilt static binary, fetched per-platform. Exposed as `pkgs.grok-cli`. |

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
