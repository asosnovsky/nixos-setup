# modules/nixos/server/arrs/

The *arr media-automation stack (Prowlarr / Sonarr / Radarr) plus a shared PostgreSQL
backend. `arrs/default.nix` defines a `makeConfig` helper that generates a consistent option
set (enable, package, openFirewall, user/group, fixed uid/gid, port) for each *arr app.

## Files

```
arrs/
├── default.nix    # skyg.server.arrs.* — shared options + makeConfig per-app option builder
├── db.nix         # Shared PostgreSQL instance for the *arr apps
└── prowlarr.nix   # Prowlarr service definition
```

## Fixed identities & ports

| App      | uid/gid | default port |
|----------|---------|--------------|
| prowlarr | 9000    | 9096         |
| sonarr   | 9001    | 8989         |
| radarr   | 9002    | 7878         |

Postgres listens on `5432`; shared data lives under `/var/lib/arrs` (`rootDataDir`).

## Option Namespace

```
skyg.server.arrs.enable
skyg.server.arrs.openFirewall
skyg.server.arrs.rootDataDir
skyg.server.arrs.database.port
skyg.server.arrs.{prowlarr,sonarr,radarr}.{enable,package,openFirewall,user,group,uid,gid,port}
```

## Conventions

- New *arr apps should be added via the `makeConfig` helper with a unique uid/gid/port, then
  given their own definition file (mirroring `prowlarr.nix`).
- Keep the fixed uid/gid scheme stable — it keeps NFS-backed data ownership consistent.
