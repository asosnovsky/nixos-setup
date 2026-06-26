# modules/nixos/server/k3s/

Single-binary **K3s** cluster role. Lightweight Kubernetes used for the homelab cluster.

## Files

```
k3s/
└── default.nix   # skyg.nixos.server.k3s.*
```

## Behaviour

- Enables `services.k3s` with `role` (`server` or `agent`) and an optional `environmentFile`
  (`envPath`, e.g. for the join token).
- Extra flags: disables the bundled servicelb and helm-controller, and writes the kubeconfig
  group-readable to the `users` group.
- Opens the standard control-plane/data-plane ports: 6443, 80, 443, 10250–10252, 8472
  (flannel), 51820 (wireguard).

## Option Namespace

```
skyg.nixos.server.k3s.enable
skyg.nixos.server.k3s.role      # "server" | "agent"  (default "server")
skyg.nixos.server.k3s.envPath   # path to environmentFile (e.g. token); "" to skip
```

## Conventions

- K3s and the full `k8s/` role are mutually exclusive — a host runs one or the other.
- Keep cluster join tokens out of the repo; point `envPath` at an agenix-managed file.
