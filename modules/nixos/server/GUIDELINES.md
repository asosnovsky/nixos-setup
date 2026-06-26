# Guidelines — modules/nixos/server/

How to add and modify homelab server roles/services. Read alongside the repo-root
`GUIDELINES.md`.

---

## Anatomy of a service module

Most files here follow the same shape. When adding a new service, mirror an existing one
(`jellyfin.nix` for a simple native service, `dockge.nix`/`scrypted.nix` for containerized
NFS-backed services):

```nix
{ config, lib, pkgs, ... }:
let cfg = config.skyg.nixos.server.services.<name>;
in {
  options.skyg.nixos.server.services.<name> = {
    enable = lib.mkEnableOption "Enable <Name>";
    openFirewall = lib.mkEnableOption "Open ports for <Name>";   # if it serves traffic
    port = lib.mkOption { type = lib.types.port; default = <n>; };
  };
  config = lib.mkIf cfg.enable {
    # ...
  };
}
```

Then add it to `services/default.nix`'s `imports` list (and to the `services/ABOUTME.md`).

## Rules

1. **Always gate with `lib.mkIf cfg.enable`.** Default `enable` to `false`. There is no
   master server switch — each service is turned on per-host in `hosts/<hostname>.nix`.
2. **Never open firewall ports unconditionally.** Expose an `openFirewall` option and wrap
   the `allowedTCPPorts`/`allowedUDPPorts` in `lib.mkIf cfg.openFirewall`.
3. **Pick the namespace that matches the neighbours.** Service modules under `services/` and
   the K3s/K8s roles use `skyg.nixos.server.*`; the older cross-cutting modules
   (`admin`, `exporters`, `timers`, `arrs`, `dns`) use `skyg.server.*`. Don't invent a third.
4. **Containers go through `virtualisation.oci-containers`.** This honours the Docker/Podman
   choice from `modules/nixos/common/containers/`. Don't hardcode `docker run` in a service
   (the `openwrt` deploy script is the only sanctioned shell-out, and it lives elsewhere).
5. **NFS-backed volumes**: create them with `system.activationScripts` + `docker volume
   create --driver local --opt type=nfs` (see `dockge.nix`), and reference homelab hosts by
   their `*.lab.internal` names.
6. **Scheduled jobs** (backups, auto-updates) should use the `skyg.server.timers.<name>`
   helper in `timers.nix` rather than hand-writing `systemd.timers`/`systemd.services`.
7. **Secrets** (tokens, API keys, join tokens) come from **agenix** (`config.age.secrets.*`)
   or an `environmentFile` path — never hardcoded, never committed. See `openclaw.nix` for
   the agenix-token pattern and `k3s/`/`dns/routing/` for `envPath`/secret-file patterns.
8. **Stable identities.** Where a service stores data on NFS, keep its `uid`/`gid` fixed and
   unique (see `arrs/` and `jellyfin.nix`) so ownership survives across hosts.

## Gotcha: openclaw.nix

`openclaw.nix` is **not** imported by `services/default.nix`. If you enable it, import it
explicitly. Don't assume every file in `services/` is wired in.

## Validation

Do **not** build or switch (see root `GUIDELINES.md`). Use `nix-instantiate --parse` on the
file for a syntax check; the user applies and verifies the service themselves.
