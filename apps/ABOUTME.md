# apps/

Standalone application binaries and AppImages that are not managed through Nix packages.

## Contents

| File | Description |
|---|---|
| `tabby-1.0.205-linux-arm64.AppImage` | Tabby AI coding assistant — ARM64 AppImage for manual deployment |

## Notes

- Files here are **not** referenced by the flake directly
- AppImages in this folder are deployed or run manually as needed
- Do not add packages here that can be expressed as proper Nix derivations — use `pkgs/` instead
