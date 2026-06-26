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
│       ├── mod.rs      # re-exports dnsmasq + ethers
│       ├── dnsmasq.rs  # renders dnsmasq.conf (server= + address= lines)
│       └── ethers.rs   # renders /etc/ethers (MAC → name/IP)
└── target/             # gitignored Cargo build output — ignore it
```

## Usage

```
openwrt-gen dnsmasq < config.json   # prints dnsmasq.conf
openwrt-gen ethers  < config.json   # prints /etc/ethers
```

## Input shape (`config.rs`)

- `generalMappings`: `[{ ip, domains[] }]` — shared domain→IP records.
- `networks`: `{ <network>: [ { mac, name, id?, domains?, justMac? } ] }` — per-network hosts.
- `dnsResolvers`: `[{ ip, port?, name? }]` — upstream `server=` entries for dnsmasq.

## Conventions

- This crate has **no I/O of its own** beyond stdin/stdout — config decryption and SSH
  delivery are the deploy script's job. Keep it a pure JSON → text transformer.
- `config.rs` carries unit tests; run `cargo test` here when changing the parser. Building
  the Nix package is fine (it doesn't touch a live system), but is not required — the user
  validates deploys via `openwrt-deploy`.
- Keep `Cargo.lock` committed and in sync (the Nix build pins to it).
