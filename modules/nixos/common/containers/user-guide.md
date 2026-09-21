# Container Services — User Guide

Declares Docker Compose stacks in Nix. Each group is rendered to a `compose.yml`,
staged on disk, and managed by a systemd oneshot unit.

## Where things live

| What                                                                             | Path                                                        |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Staged compose file                                                              | `/var/lib/container-services/<group>/compose.yml`           |
| Staged overrides file (composeFile groups with networks/volumes/extraConfig set) | `/var/lib/container-services/<group>/compose.overrides.yml` |
| Nix store source                                                                 | `/nix/store/…-compose.yml` (copied on each activation)      |
| Systemd unit                                                                     | `container-services-<group>.service`                        |
| Container logs                                                                   | `docker compose -p <group> logs -f <service>`               |
| Unit journal                                                                     | `journalctl -u container-services-<group> -f`               |

## Quick reference

```bash
# See what's running
docker compose -p <group> ps

# Follow container logs
docker compose -p <group> logs -f <service>

# Inspect the generated compose file
cat /var/lib/container-services/<group>/compose.yml

# Restart the stack (e.g. after nixos-rebuild switch)
systemctl restart container-services-<group>

# Stop / start without a rebuild
systemctl stop container-services-<group>
systemctl start container-services-<group>

# Shell into a running container
docker compose -p <group> exec <service> bash

# Pull a new image and recreate
docker compose -p <group> pull
systemctl restart container-services-<group>
```

## Debugging

### Unit fails to start

```bash
systemctl status container-services-<group>
journalctl -u container-services-<group> -n 50
```

Common causes:

- **Docker not running** — `systemctl status docker`
- **Secret path missing** — agenix may not have decrypted yet; check `systemctl status agenix`
- **Port already in use** — another service holds the host port; `ss -tlnp | grep <port>`
- **Image not pullable** — network issue or wrong image name; try `docker pull <image>` manually

### Container starts but misbehaves

```bash
# Last 100 lines from the container
docker compose -p <group> logs --tail=100 <service>

# Inspect the compose file Nix generated
cat /var/lib/container-services/<group>/compose.yml

# Verify env file was read correctly (check what the container sees)
docker compose -p <group> exec <service> env | grep <KEY>
```

### Permission errors on the data volume

The container's init runs as root and chowns `/opt/data` to `PUID:PGID`. If it still
fails, check ownership on the host:

```bash
ls -la /var/lib/<service-data-dir>
# Should match PUID:PGID set in environment {}
```

If the directory was created by a previous run as root and never chowned, remove it and
let Docker recreate it (named volumes are unaffected; only bind mounts need this):

```bash
sudo rm -rf /var/lib/<service-data-dir>
systemctl restart container-services-<group>
```

### compose.yml looks wrong

The file at `/var/lib/container-services/<group>/compose.yml` is overwritten on every
`ExecStartPre`. If it looks wrong, check the Nix-rendered source in the store directly:

```bash
# Find the store path
systemctl cat container-services-<group> | grep ExecStartPre
# Then cat it
cat /nix/store/…-compose.yml
```

If the store file is wrong, the bug is in your Nix options — rebuild with
`nixos-rebuild build` and inspect the new store path before switching.

## Custom Files

Mount custom files into containers via the `files` option:

```nix
services.app = {
  image = "my/app";
  files = {
    "/etc/app/config.yaml" = ''
      server:
        port: 8080
    '';
    "/usr/local/bin/startup.sh" = ''
      #!/bin/bash
      echo "Starting..."
    '';
  };
};
```

Files are:

- Written to `/var/lib/container-services/<group>/files/` on the host
- Mounted read-only into the container at the specified paths
- Updated automatically when you rebuild
- Changes trigger an automatic restart (via the `container-services-<group>-files` unit)

---

## Secret Compose Definitions (External `composeFile`)

Keep a whole stack's definition out of version control by storing it in an
agenix secret and pointing the group at it:

```nix
# In your host file
age.secrets.my-stack = {
  file = ../secrets/my-stack.age;
};
skyg.nixos.common.container-services.my-stack = {
  enable = true;
  composeFile = config.age.secrets.my-stack.path;
  # Optional: merged in as a base layer, overridden by composeFile itself
  # on any overlapping keys.
  networks = {
    lan = {
      driver = "macvlan";
      driver_opts.parent = "enp2s0";
    };
  };
};
```

When `composeFile` is set, the module:

- Copies that file to `/var/lib/container-services/<group>/compose.yml` at
  startup, just like a rendered one. It must define `services` itself —
  ignores this group's `services`/`files` blocks.
- If this group also sets `networks`/`volumes`/`extraConfig`, those are
  rendered to `/var/lib/container-services/<group>/compose.overrides.yml` and
  passed to compose **before** the composeFile (`-f compose.overrides.yml -f
compose.yml`), so compose's native multi-file merge applies —
  composeFile's own definitions win on any overlapping keys.
- Requires exactly one of `composeFile` or `services` to be set (assertion).

Notes:

- `env_file:` entries in the external file resolve **relative to**
  `/var/lib/container-services/<group>/`. Use absolute paths (e.g. another
  agenix secret path) or inline `environment:` instead.
- Create the secret with `skyg encrypt <secret-name>`.

---

## Shared Networks (created on the host)

Compose networks declared inside a group are scoped to that group's compose project, so two
groups would each get their own copy. To share **one** network across several stacks (e.g. a
single macvlan network), declare it once with `skyg.nixos.common.containers.networks` and
reference it as `external` via its computed `compose` attribute:

```nix
# once, e.g. in the host file
skyg.nixos.common.containers.networks.lab = {
  driver = "macvlan";
  driverOpts.parent = "eno1";
  subnet = "10.0.0.0/16";
  gateway = "10.0.0.1";
  ipRange = "10.0.101.16/28";
};

skyg.nixos.common.container-services.my-stack = {
  enable = true;
  networks = {
    internal = { driver = "bridge"; };
    lan = config.skyg.nixos.common.containers.networks.lab.compose;
  };
  services.app = {
    image = "example/app:latest";
    networks = {
      internal = { };
      lan = { ipv4_address = "10.0.101.3"; };
    };
  };
};
```

The network is created by a host systemd unit (`container-network-<name>.service`) before any
group starts; groups only reference it (`external: true`) and never create it.

---

## Internal DNS names

A service with a static IP can declare its own internal DNS name. The record is folded into
`skyg.dns.records`, aggregated across every host at the flake level, and pushed to the
OpenWrt router's `dnsmasq.conf` by `skyg openwrt`. **Nothing is configured on the host.**

```nix
skyg.nixos.common.container-services.drawdb.services.drawdb = {
  image = "ghcr.io/drawdb-io/drawdb:latest";
  networks = { lan = { ipv4_address = "10.0.101.2"; }; };
  dns.names = [ "drawdb" ];   # -> drawdb.app.internal
};
```

| Option | Default | Notes |
|---|---|---|
| `dns.names` | `[ ]` | Bare labels get `skyg.dns.domain` (default `app.internal`) appended; names containing a `.` are used as-is. |
| `dns.ip` | `null` | Derived from the service's `networks` block when it contains exactly one `ipv4_address`. Required for host-networked or multi-network services. |
| `dns.wildcard` | `false` | `true` also resolves every subdomain (`address=/name/ip` instead of `host-record=`). |

Setting `dns.names` without a derivable address is an **eval error** that names the offending
service. Two hosts mapping the same name to different IPs is also an eval error.

For IPs that aren't container services, use the host-level escape hatch instead:

```nix
skyg.dns.extraRecords.nas = { ip = "10.0.0.50"; names = [ "nas" "files" ]; };
```

Verify and deploy:

```sh
nix eval .#dnsRecords --json | jq     # every record, all hosts
skyg openwrt --dry-run                # render dnsmasq.conf locally
skyg openwrt                          # diff + confirm + apply
```

---

## Limitations

- **One unit per group.** No per-container systemd units. Use `docker compose logs` for
  container output, `journalctl` only for the start/stop lifecycle.
- **`compose down` on stop.** Containers are removed when the unit stops. Data in
  bind mounts and named volumes is preserved.
- **Compose project name == group name.** Keep group names DNS-label–safe (letters,
  digits, hyphens).
