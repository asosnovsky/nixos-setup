# modules/nixos/common/containers/

Container runtime configuration and compose-style service groups.

## Files

```
containers/
├── default.nix            # Shared runtime options (runtime, enableOnBoot, registries, metrics)
├── docker.nix             # Applied when runtime == "docker"
├── podman.nix             # Applied when runtime == "podman" (dockerCompat + socket)
├── container-services/    # Compose-style service groups (modular implementation)
│   ├── default.nix
│   ├── options.nix
│   ├── lib.nix
│   ├── compose.nix
│   ├── files.nix
│   ├── systemd.nix
│   └── ABOUTME.md
└── user-guide.md          # Full usage docs for container-services
```

## Runtime selection (`skyg.nixos.common.containers`)

Picks **one** of Docker or Podman based on `runtime` and configures it
consistently (compose tooling, user group membership, OCI backend, metrics).

- `runtime` defaults to `"docker"`. Each backend file gates on `cfg.runtime == "<name>"`,
  so exactly one applies.
- **Docker** enables autoprune, sets `insecure-registries` from `localDockerRegistries`
  (default `minipc1.lab.internal:5001`), exposes metrics on `metricsPort` (9323), adds the
  user to the `docker` group, and installs `docker-compose`.
- **Podman** enables `dockerCompat` + docker socket so `docker`/`oci-containers` keep working,
  and installs `podman-compose` + `podman-tui`.
- `openMetricsPort` opens the metrics port in the firewall (Docker only).

### Option namespace

```
skyg.nixos.common.containers.runtime               → "docker" | "podman"
skyg.nixos.common.containers.enableOnBoot
skyg.nixos.common.containers.localDockerRegistries
skyg.nixos.common.containers.metricsPort
skyg.nixos.common.containers.openMetricsPort
```

## Container service groups (`skyg.nixos.common.container-services`)

A compose-like abstraction that:

1. Converts a Nix attrset into a real `compose.yml` via `pkgs.formats.yaml`.
2. Stages it to `/var/lib/container-services/<group>/compose.yml` at activation.
3. Manages the whole stack with one systemd oneshot unit per group:
   `container-services-<group>.service`.

```nix
skyg.nixos.common.container-services.my-stack = {
  services.app = {
    image  = "example/app:latest";
    ports  = [ "8080:8080" ];
    volumes = [ "/var/lib/app:/data" ];
    environmentFiles = [ config.age.secrets.app-env.path ];
    extraConfig.shm_size = "512m";
  };
};
```

See [user-guide.md](./user-guide.md) for the full option reference and day-2 ops.

For module implementation details, see [container-services/ABOUTME.md](./container-services/ABOUTME.md).

## Conventions

- Always select the runtime via `skyg.nixos.common.containers.runtime`; do not enable both
  backends manually.
- `virtualisation.oci-containers.backend` is set by whichever runtime is active, so server
  service modules can declare containers backend-agnostically via `virtualisation.oci-containers`.
- Prefer `container-services` for new stacks. Only reach for raw
  `virtualisation.oci-containers.containers` for single-container services with no
  inter-container networking needs.
