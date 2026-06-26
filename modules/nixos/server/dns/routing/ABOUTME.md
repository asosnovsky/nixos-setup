# modules/nixos/server/dns/routing/

Local DNS resolver backed by **dnsmasq**. Serves static domain→IP mappings for the homelab
and forwards everything else upstream.

## Files

```
routing/
└── default.nix   # skyg.server.dns.routing.*
```

## Behaviour

- Each `addresses` entry `{ domain, ip }` produces **both** an exact (`/domain/ip`) and a
  wildcard (`/.domain/ip`) dnsmasq `address=` line.
- `addressesSecretName` points at an agenix secret (`secrets/<name>.age`) whose decrypted
  contents are a dnsmasq fragment, included via `conf-file` — used for records that should
  not live in the public repo.
- `upstreamServers` (default `1.1.1.1`, `1.0.0.1`) handle unresolved queries.
- `listenAddresses` (empty = all interfaces) and `openFirewall` (port 53 UDP/TCP) control
  exposure.

## Option Namespace

```
skyg.server.dns.routing.enable
skyg.server.dns.routing.addresses            # [{ domain, ip }]
skyg.server.dns.routing.addressesSecretName  # agenix secret name, or null
skyg.server.dns.routing.upstreamServers
skyg.server.dns.routing.listenAddresses
skyg.server.dns.routing.openFirewall
```

## Conventions

- Put private/sensitive records in the agenix secret, not in `addresses`.
- The `age.secrets` reference resolves relative to the repo `secrets/` directory — manage
  that file with `skyg secrets`, never by hand.
