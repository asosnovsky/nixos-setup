# modules/nixos/server/k8s/

Full upstream **Kubernetes** role (as opposed to the lighter `k3s/`). Splits responsibilities
into master and node modules under a shared option set.

## Files

```
k8s/
├── default.nix   # skyg.nixos.server.k8s.* — shared options, firewall, services.kubernetes base
├── master.nix    # Control-plane (apiserver/scheduler/controller/etcd) config
└── node.nix      # Worker node config
```

## Behaviour

- `default.nix` adds the master hostname to `/etc/hosts` (`masterIP`/`masterHostName`), opens
  the control-plane ports (apiserver `6443`, kubelet 10250/10257/10259, etcd 2379–2380),
  installs `kubectl`/`kubernetes`, and sets `easyCerts` + DNS addon.
- A host declares its role via `isMaster` / `isNode`.

## Option Namespace

```
skyg.nixos.server.k8s.enable
skyg.nixos.server.k8s.isMaster
skyg.nixos.server.k8s.isNode
skyg.nixos.server.k8s.masterIP
skyg.nixos.server.k8s.masterHostName
skyg.nixos.server.k8s.masterAPIPort   # default 6443
```

## Conventions

- Use either this full `k8s` role or `k3s` on a host, not both.
- `masterIP`/`masterHostName` must be set on every member so the cluster can resolve the
  control plane.
