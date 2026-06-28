# container-services/

Custom compose-style container service groups for systemd.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Main module entry point; imports options and wires everything |
| `options.nix` | All `skyg.nixos.common.container-services.*` option declarations |
| `lib.nix` | Shared helpers (runtime dispatch, path sanitization, env file collection) |
| `compose.nix` | YAML composition (mkComposeService, mkComposeAttrs, mkComposeFile) |
| `files.nix` | File mounting logic (getAllFiles, mkFileVolumesForService, mkFilesService) |
| `systemd.nix` | Systemd unit builders (mkSystemdService, mkPathUnit, mkEnvReloadService) |

## How it works

1. User declares a group under `skyg.nixos.common.container-services.<group>`
2. `options.nix` validates the structure
3. `lib.nix` provides runtime dispatch (docker vs podman)
4. `compose.nix` renders a YAML compose file with all services
5. `files.nix` collects custom files, generates write commands, and builds file volume mounts
6. `systemd.nix` builds oneshot units to manage the stack
7. `default.nix` wires tmpfiles, services, and paths together

## Adding a new feature

If adding a new per-service option:

1. Add it to the submodule in `options.nix`
2. Update the builder(s) in `compose.nix`, `files.nix`, or `systemd.nix` as needed
3. Update `user-guide.md` with examples

## Architecture

- Each group gets **one** systemd unit (`container-services-<group>.service`) that manages the whole stack
- Custom files are collected and written by a separate unit (`container-services-<group>-files.service`)
- Env file changes trigger a path unit that restarts the stack (`container-services-<group>-env-reload.*`)
- Compose files are rendered to the store and staged to `/var/lib/container-services/<group>/compose.yml`
