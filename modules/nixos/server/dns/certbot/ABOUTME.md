# modules/nixos/server/dns/certbot/

Let's Encrypt certificate management via **certbot** + the nginx plugin, for public-facing
domains.

## Files

```
certbot/
└── default.nix   # skyg.server.dns.certbot.*
```

## Behaviour

- Installs `certbot` + `certbot-nginx` and enables nginx.
- Sets up a `certbot-renew` systemd service + daily timer (uses `renew --dry-run` when
  `testMode = true`).
- Provides a `certbot-get-certs` shell alias that runs a non-interactive
  `certonly --nginx` for every domain in `publicDomains`, registered with `email`.

## Option Namespace

```
skyg.server.dns.certbot.enable
skyg.server.dns.certbot.publicDomains   # list of domains
skyg.server.dns.certbot.email           # ACME account email
skyg.server.dns.certbot.testMode        # dry-run renewals
```

## Conventions

- Initial issuance is manual (run `certbot-get-certs`); renewal is automated by the timer.
- For internal-only domains use the `local-ca` sibling module instead of Let's Encrypt.
