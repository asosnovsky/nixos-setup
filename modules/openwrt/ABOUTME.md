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
2. `openwrt-deploy` reads the decrypted JSON from stdin, runs `openwrt-gen dnsmasq`,
   `openwrt-gen ethers`, and `openwrt-gen firewall` to render the three target files.
3. It SSHes to the router, shows a **colorized unified diff** against the current files
   (for the firewall, only the `skyg_*`-managed rules are diffed), each with a
   `-> N added, M removed` summary, then lists the `skyg_*` rule names that will be
   applied, and prompts for confirmation.
4. On the router it **backs up** the configs it overrides to `/etc/skyg-backups/` with a
   timestamp, then applies them. `dnsmasq.conf` is validated with `dnsmasq --test` and the
   firewall is committed + reloaded; **any failure auto-restores** from that timestamp's
   backups. Backups persist so you can restore later if something breaks:
   ```sh
   cp /etc/skyg-backups/firewall.<ts> /etc/config/firewall
   uci commit firewall && /etc/init.d/firewall restart
   ```

```
age -d secrets/glmain.json.age | openwrt-deploy
```

### Dry run (no router changes)

`openwrt-dry-run` renders the same three configs **locally** and writes them to
`.tmp/openwrt-<router>/` for review — no SSH, no `uci`, no confirm prompt. The router name
is passed as a command-line argument (default `glmain`).

```bash
skyg openwrt --dry-run
# → .tmp/openwrt-glmain/dnsmasq.conf
# → .tmp/openwrt-glmain/ethers
# → .tmp/openwrt-glmain/firewall.batch   # the exact `uci batch` that would be applied
```

Use this to inspect what a deploy *would* do (especially the firewall rules) before running
the real `skyg openwrt`.

`router.ip` / `router.user` are taken from the `config` passed into `default.nix`.

## Conventions

- The router config is a **secret** — decrypt it on the fly; never commit the plaintext JSON.
- Deploys are interactive and reviewed by a human; the script intentionally requires
  confirmation and self-reverts on a bad dnsmasq config.
- `generator/target/` is gitignored Rust build output — ignore it.
- Firewall rules are **managed by name**: the deploy script only touches rules named
  `skyg_*`. It deletes existing `skyg_*` rules, adds the newly generated ones, commits, and
  reloads — so deploys are idempotent and never clobber hand-written rules.
