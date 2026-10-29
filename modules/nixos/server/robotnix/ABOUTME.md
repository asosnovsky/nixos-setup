# robotnix — adapter for the robotnix flake

robotnix (self-managed NixOS `systemd-nspawn` robots) lives in its own repo:
`git+ssh://gitea@gitea.app.internal:22/ari/robotnix.git`, a flake input of
this repo. Its README and `docs/` describe the design, options, CLI and
tests. Hosts configure it under `services.robotnix` (like `services.hermenix`).

This folder only holds `default.nix`, which:

- imports `robotnix.nixosModules.default` (passed in via `specialArgs`);
- defaults `user`, `authorizedKeys`, `dnsUpstreams` and `localDomains` from
  the `skyg` user, the SSH master keys and the internal networking map;
- asserts no robot address clashes with an app in
  `skyg.internalNetworkingMap.apps`.

## Decisions

- **Own repo** (2026-10): robotnix moved out of `modules/nixos/server` so it
  can grow (storage backends, Genix, child robots) with its own tests.
- **Namespace**: `services.robotnix`, not `skyg.*`, same exception as
  hermenix: the options belong to an external flake.
- **hermes-agent pin**: the input follows this repo's `hermes-agent`, so
  robots pin the same revision the host locked.
- **Buzz stays here**: robotnix knows nothing about Buzz. The robots' shared
  `hosts/hl-fwdesk/services/robotnix/buzz.nix` builds `pkgs/buzz-cli` from
  this repo and sets `BUZZ_CLI_PATH`. Robots get copies of it, `common.nix`
  and `pkgs/buzz-cli` under `/etc/nixos/seed` (robotnix `seed.extraFiles`,
  `seedOf` in the host file), so a robot that rebuilds itself (genix) has
  its own copy.
- **nspawn, not `oci-containers`**: the oci-containers rule targets
  Docker/Podman. nspawn robots need their own store for self-rebuilds, which
  the `containers.*` module can't give.
