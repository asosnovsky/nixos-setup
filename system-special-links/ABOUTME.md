# system-special-links/

Tracked repository copies of files that live at special system paths outside the normal
Nix store — primarily Kubernetes configs and persistent service data that must be
version-controlled but can't be managed as Nix derivations.

## Contents

| Directory | Description |
|---|---|
| `k3s-configs/` | K3s cluster configuration files (manifests, kubeconfig templates) |
| `terra1-apps/` | Application data layouts for `hl-terra1` NFS-backed services |

## Notes

- Files here are **not** automatically deployed by the flake
- They are synced to target hosts manually or via the `skyg remote` workflow
- Do not store secrets here — use `secrets/` with agenix instead
