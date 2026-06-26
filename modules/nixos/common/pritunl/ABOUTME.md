# modules/nixos/common/pritunl/

Pritunl VPN **client**. Installs `pritunl-client` and runs the
`pritunl-client-service` systemd unit so VPN profiles can be managed on the host.

## Files

```
pritunl/
└── default.nix   # skyg.nixos.common.pritunl.enable
```

## Option Namespace

```
skyg.nixos.common.pritunl.enable   # default false
```

## Conventions

- This only provisions the client daemon; VPN profiles/credentials are imported at runtime,
  not declared here.
