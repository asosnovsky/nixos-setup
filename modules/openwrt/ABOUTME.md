# modules/openwrt/

Config generator + deploy tooling for the homelab's **OpenWrt** router. This is *not* a NixOS
module — it's a Nix function that builds a Rust generator and wraps it in an
`openwrt-deploy` shell script. OpenWrt is managed out-of-band (the router isn't a NixOS host),
so this provides a declarative, reviewable way to push `dnsmasq.conf` and `/etc/ethers`.

## Structure

```
openwrt/
├── default.nix   # Builds the Rust generator + the openwrt-deploy script
└── generator/    # Rust crate (openwrt-gen) that turns a JSON config into OpenWrt files
```

## How it works

1. The router config lives as an **agenix secret** (e.g. `secrets/glmain.json.age`).
2. `openwrt-deploy` reads the decrypted JSON from stdin, runs `openwrt-gen dnsmasq` and
   `openwrt-gen ethers` to render the two target files.
3. It SSHes to the router, shows a **colorized diff** against the current files, and prompts
   for confirmation before writing.
4. `dnsmasq.conf` is validated with `dnsmasq --test` on the router and **automatically
   reverted** if the new config is invalid.

```
age -d secrets/glmain.json.age | openwrt-deploy
```

`router.ip` / `router.user` are taken from the `config` passed into `default.nix`.

## Conventions

- The router config is a **secret** — decrypt it on the fly; never commit the plaintext JSON.
- Deploys are interactive and reviewed by a human; the script intentionally requires
  confirmation and self-reverts on a bad dnsmasq config.
- `generator/target/` is gitignored Rust build output — ignore it.
