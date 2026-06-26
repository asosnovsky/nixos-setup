# modules/nixos/server/

Opt-in server roles and self-hosted services for the homelab. `default.nix` imports every
subtree; each module/service is individually enabled — there is **no** single master server
switch, so a host only runs what it explicitly turns on.

## Structure

```
server/
├── default.nix    # imports everything below
├── admin.nix      # skyg.server.admin — www-data group/user for shared web data
├── exporters.nix  # skyg.server.exporters — Prometheus node exporter (:9100)
├── timers.nix     # skyg.server.timers — generic attrset → systemd timer+oneshot service
├── arrs/          # *arr media-automation stack (prowlarr/sonarr/radarr) + postgres
├── dns/           # Local DNS resolver, certbot, local CA
├── k3s/           # Single-binary K3s cluster role
├── k8s/           # Full upstream Kubernetes (master/node)
└── services/      # Self-hosted apps (jellyfin, audiobookshelf, comfyui, scrypted, dockge, ai…)
```

## Notable details

- **`timers.nix`** is a reusable helper: anything added to `skyg.server.timers.<name>`
  (with `script`, `OnCalendar`, `wantedBy`) becomes a systemd timer + oneshot service. Other
  modules (e.g. `services/scrypted.nix`) use it for backups/auto-updates.
- **`exporters.nix`** enables the Prometheus node exporter with the systemd collector and
  opens port 9100.
- Naming: this tree mostly uses the legacy `skyg.server.*` prefix for cross-cutting modules
  (admin/exporters/timers/arrs/dns) and `skyg.nixos.server.*` for the K3s/K8s roles and the
  service modules under `services/`.

## Option Namespace

```
skyg.server.admin.enable          → admin.nix
skyg.server.exporters.enable      → exporters.nix
skyg.server.timers.<name>         → timers.nix
skyg.server.arrs.*                → arrs/
skyg.server.dns.*                 → dns/
skyg.nixos.server.k3s.*           → k3s/
skyg.nixos.server.k8s.*           → k8s/
skyg.nixos.server.services.*      → services/
```

## Conventions

- Every role/service defaults to `false`; enable per-host in `hosts/<hostname>.nix`.
- Services that need ports should expose an `openFirewall` option rather than opening ports
  unconditionally. See `GUIDELINES.md` in this folder for the full service-authoring pattern.
