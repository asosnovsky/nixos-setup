# Container Services — User Guide

Declares Docker Compose stacks in Nix. Each group is rendered to a `compose.yml`,
staged on disk, and managed by a systemd oneshot unit.

## Where things live

| What | Path |
| ---- | ---- |
| Staged compose file | `/var/lib/container-services/<group>/compose.yml` |
| Nix store source | `/nix/store/…-compose.yml` (copied on each activation) |
| Systemd unit | `container-services-<group>.service` |
| Container logs | `docker compose -p <group> logs -f <service>` |
| Unit journal | `journalctl -u container-services-<group> -f` |

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

## Limitations

- **One unit per group.** No per-container systemd units. Use `docker compose logs` for
  container output, `journalctl` only for the start/stop lifecycle.
- **`compose down` on stop.** Containers are removed when the unit stops. Data in
  bind mounts and named volumes is preserved.
- **Compose project name == group name.** Keep group names DNS-label–safe (letters,
  digits, hyphens).
