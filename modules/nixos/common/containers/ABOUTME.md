# modules/nixos/common/containers/

Container runtime configuration and compose-style service groups.

## Files

```
containers/
├── default.nix            # Shared runtime options (runtime, enableOnBoot, registries, metrics)
├── docker.nix             # Applied when runtime == "docker"
├── podman.nix             # Applied when runtime == "podman" (dockerCompat + socket + registries)
├── networks.nix           # Host-created container networks (skyg.nixos.common.containers.networks)
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
  allows plain-HTTP pulls from `localDockerRegistries` via
  `virtualisation.containers.registries.settings`, and installs `podman-compose` + `podman-tui`.
- `openMetricsPort` opens the metrics port in the firewall (Docker only).

### Option namespace

```
skyg.nixos.common.containers.enable                 → false to disable the container runtime entirely
skyg.nixos.common.containers.runtime               → "docker" | "podman"
skyg.nixos.common.containers.enableOnBoot
skyg.nixos.common.containers.localDockerRegistries
skyg.nixos.common.containers.metricsPort
skyg.nixos.common.containers.openMetricsPort
skyg.nixos.common.containers.networks.<name>.*     → networks.nix (host-created networks)
```

## Host-created networks (`skyg.nixos.common.containers.networks`)

Creates container networks once on the host (one systemd oneshot each, ordered before
`container-networks.target`), independent of any compose project. This is how a _single_
network — e.g. one macvlan network — is shared by several `container-services` groups
instead of being re-declared (and re-created) per stack.

```nix
skyg.nixos.common.containers.networks.lab = {
  driver = "macvlan";
  driverOpts.parent = "eno1";
  subnet = "10.0.0.0/16";
  gateway = "10.0.0.1";
  ipRange = "10.0.101.16/28";
};
```

Each network exposes a computed `compose` attribute (an `external: true` entry) for use in a
group's `networks` option:

```nix
skyg.nixos.common.container-services.my-stack = {
  networks.lan = config.skyg.nixos.common.containers.networks.lab.compose;
  services.app.networks.lan = { ipv4_address = "10.0.101.3"; };
};
```

Fields: `enable`, `name` (default = attr name), `driver`, `driverOpts`, `subnet`, `gateway`,
`ipRange`, `internal`. Works with both docker and podman.

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
