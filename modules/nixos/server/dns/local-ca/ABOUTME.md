# modules/nixos/server/dns/local-ca/

Scaffolding for an internal Certificate Authority used to issue certs for private
`*.internal` domains that should not go through Let's Encrypt.

## Files

```
local-ca/
└── default.nix   # skyg.server.dns.local-ca.*
```

## Status & behaviour

- Creates `/etc/ssl/local-ca` and a `local-ca-setup` oneshot service.
- **The actual CA key/cert generation is currently scaffolded** — the openssl invocation in
  `local-ca-setup` is commented out, and the `ca-certificates.crt` entry is a placeholder.
  Treat this module as a structural stub to build on, not a working CA yet.

## Option Namespace

```
skyg.server.dns.local-ca.enable
skyg.server.dns.local-ca.{caCert,caKey,domain,organizationalUnit,organization,country,email,certificateLifetime}
```

## Conventions

- If you implement real key generation here, do **not** commit private keys; persist them
  outside the Nix store and reference them by path (or manage with agenix).
