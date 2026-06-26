# modules/nixos/common/containers/

Container runtime configuration. Picks **one** of Docker or Podman based on
`skyg.nixos.common.containers.runtime` and configures it consistently (compose tooling,
user group membership, OCI backend, metrics).

## Files

```
containers/
├── default.nix   # Shared options: runtime, enableOnBoot, registries, metrics port
├── docker.nix    # Applied when runtime == "docker"
└── podman.nix    # Applied when runtime == "podman" (dockerCompat + socket)
```

## Behaviour

- `runtime` defaults to `"docker"`. Each backend file gates on `cfg.runtime == "<name>"`,
  so exactly one applies.
- **Docker** enables autoprune, sets `insecure-registries` from `localDockerRegistries`
  (default `minipc1.lab.internal:5001`), exposes metrics on `metricsPort` (9323), adds the
  user to the `docker` group, and installs `docker-compose`.
- **Podman** enables `dockerCompat` + docker socket so `docker`/`oci-containers` keep working,
  and installs `podman-compose` + `podman-tui`.
- `openMetricsPort` opens the metrics port in the firewall (Docker only).

## Option Namespace

```
skyg.nixos.common.containers.runtime               → "docker" | "podman"
skyg.nixos.common.containers.enableOnBoot
skyg.nixos.common.containers.localDockerRegistries
skyg.nixos.common.containers.metricsPort
skyg.nixos.common.containers.openMetricsPort
```

## Conventions

- Always select the runtime via the `runtime` option; do not enable both backends manually.
- `virtualisation.oci-containers.backend` is set by whichever runtime is active, so server
  service modules can declare containers backend-agnostically.
