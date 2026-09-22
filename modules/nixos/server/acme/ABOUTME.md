# modules/nixos/server/acme/

Let's Encrypt certificates via **DNS-01**, wrapped around NixOS
`security.acme` (lego) with this repo's conventions. Domain ownership is
proven through DNS records at the provider, so **nothing needs to be
reachable from the internet** — no port forwards, no public listeners.

## Options (`skyg.server.acme.*`)

| Option                   | Default              | Purpose                                                                                                                                                                             |
| ------------------------ | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enable`                 | `false`              | Master switch, per host.                                                                                                                                                            |
| `email`                  | `admin@sosnovsky.ca` | Let's Encrypt account contact (expiry notices).                                                                                                                                     |
| `dnsProvider`            | `"cloudflare"`       | lego DNS provider name (see lego docs).                                                                                                                                             |
| `credentialsFile`        | —                    | Env file with provider API credentials (e.g. `CLOUDFLARE_DNS_API_TOKEN=...`). Point at an agenix secret — never the Nix store.                                                      |
| `certs."<domain>"`       | `{ }`                | One block per certificate; the attribute name is the primary domain.                                                                                                                |
| `certs.*.extraDomains`   | `[ ]`                | Extra names on the same cert (SANs).                                                                                                                                                |
| `certs.*.reloadServices` | `[ ]`                | Native systemd services reloaded after each renewal.                                                                                                                                |
| `certs.*.postRun`        | `""`                 | Shell command after each renewal (e.g. `docker restart <container>` for compose stacks).                                                                                            |
| `certs.*.orderBefore`    | `[ ]`                | `systemd.services` attribute names (no `.service` suffix) that start only after the cert exists (first boot — otherwise Docker bind-mounts empty dirs over the missing cert files). |

## Usage

```nix
age.secrets.cloudflare-dns.file = ../secrets/cloudflare-dns.age;
skyg.server.acme = {
  enable = true;
  credentialsFile = config.age.secrets.cloudflare-dns.path;
  certs."app.home.sosnovsky.ca" = {
    postRun = "${pkgs.docker}/bin/docker restart my-stack-caddy-1";
    orderBefore = [ "container-services-my-stack" ];
  };
};
```

Certs land in `/var/lib/acme/<domain>/` (`fullchain.pem`, `key.pem`, …),
renewed automatically by the `acme-<domain>.service` timer; hooks run after
each renewal. The secret contains one line: `CLOUDFLARE_DNS_API_TOKEN=<token>`
(token scope: Zone → DNS → Edit, restricted to the one zone).

## ⚠ Cloudflare zone lives elsewhere (for now)

The `sosnovsky.ca` zone and the Cloudflare account/API token are managed in
`~/Projects/Homelab/homelab` (Terraform `tf-dns.tf`, cert-manager) until
DNS/SSL management migrates into this repo. When that migration happens, only
the token's provenance changes — this module is unaffected.

## Notes

- Supersedes `skyg.server.dns.certbot` (HTTP-01 + nginx, disabled) for hosts
  that are not publicly reachable. The certbot module is left untouched.
- For internal-only services whose clients all use the system trust store,
  the lab CA (`skyg ca`, see `configs/pki/ABOUTME.md`) is the simpler option —
  no public name needed.
