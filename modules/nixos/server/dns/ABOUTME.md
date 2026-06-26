# modules/nixos/server/dns/

Local DNS and certificate infrastructure for the `*.lab.internal` / `*.internal` homelab.
`default.nix` imports the three independent submodules below.

## Structure

```
dns/
├── default.nix   # imports routing/ + certbot/ + local-ca/
├── routing/      # skyg.server.dns.routing — dnsmasq resolver + static A records
├── certbot/      # skyg.server.dns.certbot — Let's Encrypt via certbot + nginx
└── local-ca/     # skyg.server.dns.local-ca — internal certificate authority scaffolding
```

## Notable details

- **`routing/`** runs dnsmasq, generating exact + wildcard `address=` entries from
  `addresses`, forwarding the rest to `upstreamServers` (default 1.1.1.1/1.0.0.1). It can
  also pull additional `address=` lines from an **agenix secret** named via
  `addressesSecretName` (decrypted into a `conf-file`).
- **`certbot/`** wires up daily `certbot renew --nginx`, with a `testMode` dry-run option and
  a `certbot-get-certs` shell alias built from `publicDomains` + `email`.
- **`local-ca/`** sets up the directory/structure for an internal CA; the actual key/cert
  generation is currently scaffolded (commented openssl steps) rather than fully implemented.

## Option Namespace

```
skyg.server.dns.routing.{enable,addresses,addressesSecretName,upstreamServers,listenAddresses,openFirewall}
skyg.server.dns.certbot.{enable,publicDomains,email,testMode}
skyg.server.dns.local-ca.{enable,caCert,caKey,domain,organization,...}
```

## Conventions

- The three submodules are independent; enable only what a host needs.
- DNS records that must stay private should live in the agenix secret referenced by
  `addressesSecretName`, not in plaintext `addresses`.
