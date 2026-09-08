# openwrt-routers/

Declarative OpenWrt router configurations, compiled to UCI (Unified Configuration Interface)
by the Rust-based generator in `modules/openwrt/generator/`.

## Contents

| File | Description |
|---|---|
| `glmain.nix` | Configuration for the `glmain` GL.iNet router (gateway at `10.0.0.1`) |

## How It Works

1. `glmain.nix` declares the router's network topology, firewall zones, DHCP, and DNS in Nix
2. `modules/openwrt/default.nix` passes it through the generator binary
3. `skyg openwrt` SSHes to the router and applies the generated UCI config

## Deploying

```bash
skyg openwrt
```

## Adding a New Router

1. Create `openwrt-routers/<name>.nix` modelled on `glmain.nix`
2. Add a `openwrt-<name>` package output in `flake.nix` using the `openwrt` helper
3. Add a deploy target in `bin/lib/cmds.nu`

## Notes

- Router credentials are stored in `secrets/glmain.json.age`
- Do not hardcode passwords or PSKs in the `.nix` file — use agenix secrets
