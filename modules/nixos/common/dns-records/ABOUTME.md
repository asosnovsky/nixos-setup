# modules/nixos/common/dns-records/

Host-level registry of **internal DNS records**. This module configures *nothing* on the
host — it is a pure data collection point. Records declared here are aggregated across all
hosts at the flake level (`nix eval .#dnsRecords`) and pushed to the OpenWrt router's
`dnsmasq.conf` by `skyg openwrt` (see `modules/openwrt/`).

## Why

Service IPs live in host configs (e.g. a container's static macvlan address in
`hosts/hl-minipc2.nix`), but the router config lives in an encrypted JSON secret. Without a
bridge, naming a service means writing its IP in two places that silently drift. This module
is the single canonical shape everything writes to:

```nix
{ ip = "10.0.101.2"; names = [ "drawdb.app.internal" ]; wildcard = false; source = "..."; }
```

## Options

| Option | Purpose |
|---|---|
| `skyg.dns.domain` | Default suffix for bare names. Default `app.internal`. |
| `skyg.dns.extraRecords` | Hand-written records, keyed by name so they can be overridden. **Use this for arbitrary IPs.** |
| `skyg.dns.records` | List form. Modules append here (container-services does). |
| `skyg.dns.resolved` | Read-only: the above, names fully qualified + `host` attached. What the aggregator reads. |
| `skyg.dns.writeDebugFile` | Dump `resolved` to `/etc/skyg/dns-records.json`. Default true. |

Names without a `.` get `skyg.dns.domain` appended: `"drawdb"` → `"drawdb.app.internal"`.
Names containing a `.` are treated as fully-qualified and passed through untouched.

`wildcard = false` (the default) emits dnsmasq `host-record=name,ip` — a plain A record with
reverse PTR. `wildcard = true` emits `address=/name/ip`, which also catches every subdomain.

## Examples

Arbitrary IP, no container involved:

```nix
skyg.dns.extraRecords.nas = {
  ip = "10.0.0.50";
  names = [ "nas" "files" ];   # -> nas.app.internal, files.app.internal
};
```

From a container service (see `containers/container-services/`, which folds into `records`):

```nix
skyg.nixos.common.container-services.drawdb.services.drawdb = {
  networks = { lan.ipv4_address = "10.0.101.2"; };
  dns.names = [ "drawdb" ];
};
```

## Deploying

Records are inert until pushed to the router:

```sh
nix eval .#dnsRecords --json | jq   # inspect the aggregate across all hosts
skyg openwrt --dry-run              # render dnsmasq.conf locally
skyg openwrt                        # diff + confirm + apply on the router
```

Conflicts (the same name mapped to two different IPs, on any host) fail flake evaluation.
