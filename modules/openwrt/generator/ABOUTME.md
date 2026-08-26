# modules/openwrt/generator/

`openwrt-gen` — a small Rust CLI that converts a single JSON network description into OpenWrt
config files. Built by `../default.nix` with `rustPlatform.buildRustPackage` and invoked by
the `openwrt-deploy` script.

## Layout

```
generator/
├── Cargo.toml          # crate metadata; deps: serde, serde_json
├── Cargo.lock          # pinned for the Nix build (cargoLock.lockFile)
├── src/
│   ├── main.rs         # CLI entry: reads JSON from stdin, dispatches on argv[1]
│   ├── config.rs       # serde Deserialize structs for the input JSON (+ unit tests)
│   ├── network.rs      # process_network — expands per-network device lists
│   └── generators/
│       ├── mod.rs      # re-exports dnsmasq + ethers + firewall
│       ├── dnsmasq.rs  # renders dnsmasq.conf (server= + address= lines)
│       ├── ethers.rs   # renders /etc/ethers (MAC → name/IP)
│       └── firewall.rs # renders UCI firewall rules (internet-only networks)
└── target/             # gitignored Cargo build output — ignore it
```

## Usage

```
openwrt-gen dnsmasq  < config.json   # prints dnsmasq.conf
openwrt-gen ethers   < config.json   # prints /etc/ethers
openwrt-gen firewall < config.json   # prints UCI firewall rules (uci batch format)
```

## Input shape (`config.rs`)

- `generalMappings`: `[{ ip, domains[] }]` — shared domain→IP records.
- `networks`: `{ <network>: [ { mac, name, id?, domains?, justMac? } ] }` — per-network hosts.
- `dnsResolvers`: `[{ ip, port?, name? }]` — upstream `server=` entries for dnsmasq.
- `internetOnly`: `[<network>, ...]` — networks restricted to internet-only access.

## Internet-only firewall rules (`firewall.rs`)

For each network in `internetOnly`, the generator emits UCI `config rule` blocks that DROP
forwarded traffic from that network to the rest of the LAN (`10.0.0.0/16`):

- **IPv4** — one rule per network matching the whole subnet (catches every device on it).
- **IPv6** — one rule per known device MAC. All subnets share a single ULA /64
  (`fd59:de0a:bff5::/48`, see `network::ULA_PREFIX`), so subnets are not distinguishable
  in IPv6 and blocking is done per known device. An *unknown* IPv6-only device on those
  subnets is **not** blocked (inherent to the flat-L2 topology).

Rules are named `skyg_<network>_drop_lan` (IPv4) and `skyg_<network>_drop_lan_v6` (IPv6) so
the deploy script owns exactly these. They are inserted before port-specific ACCEPT rules
(e.g. the existing `sambasharelan`) so the DROPs win. Reverse direction (LAN → restricted
network) stays open, and within-subnet traffic (e.g. cam→cam) is blocked.

## Conventions

- This crate has **no I/O of its own** beyond stdin/stdout — config decryption and SSH
  delivery are the deploy script's job. Keep it a pure JSON → text transformer.
- `config.rs` carries unit tests; run `cargo test` here when changing the parser. Building
  the Nix package is fine (it doesn't touch a live system), but is not required — the user
  validates deploys via `openwrt-deploy`.
- Keep `Cargo.lock` committed and in sync (the Nix build pins to it).
