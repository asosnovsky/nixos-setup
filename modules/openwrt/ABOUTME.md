# modules/openwrt/

Config generator + deploy tooling for the homelab's **OpenWrt** router. This is *not* a NixOS
module — it's a Nix function that builds a Rust generator and wraps it in an
`openwrt-deploy` shell script. OpenWrt is managed out-of-band (the router isn't a NixOS host),
so this provides a declarative, reviewable way to push `dnsmasq.conf` and `/etc/ethers`.

## Structure

```
openwrt/
├── default.nix           # Thin Nix wrapper: builds the generator, exports store paths as
│                         # env vars, and inlines the .sh files below via builtins.readFile
├── skyg-apply.sh         # Runs ON THE ROUTER (POSIX sh) — backup/apply/validate/restore
├── openwrt-deploy.sh     # openwrt-deploy's logic (bash) — reads $ROUTER/$GENERATOR/etc.
├── openwrt-dry-run.sh    # openwrt-dry-run's logic (bash) — reads $GENERATOR
└── generator/            # Rust crate (openwrt-gen) that turns a JSON config into OpenWrt files
```

The three `.sh` files are real, directly-editable/shellcheck-able scripts — `default.nix` only
supplies the Nix-computed values (router address, generator/apply-script store paths) as
exported env vars before inlining each file's content via `builtins.readFile`.

## How it works

1. The router config lives as an **agenix secret** (e.g. `secrets/glmain.json.age`).
2. `openwrt-deploy` reads the decrypted JSON from stdin, runs `openwrt-gen dnsmasq`,
   `openwrt-gen ethers`, and `openwrt-gen firewall` to render the three target files.
3. It SSHes to the router, shows a **colorized unified diff** against the current files
   (for the firewall, only the `skyg_*`-managed rules are diffed), each with a
   `-> N added, M removed` summary, then lists the `skyg_*` rule names that will be
   applied, and prompts for confirmation.
4. On the router it **backs up** the configs it overrides to `/etc/skyg-backups/` with a
   timestamp, then applies them. It also ensures `net.bridge.bridge-nf-call-iptables` /
   `-ip6tables` are enabled via a managed block in `/etc/sysctl.conf` (see Conventions below
   — required for the firewall rules to actually see LAN-to-LAN traffic). `dnsmasq.conf` is
   validated with `dnsmasq --test` and the firewall is committed + reloaded; **any failure
   auto-restores** from that timestamp's backups. Backups persist so you can restore later if
   something breaks:
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
# → .tmp/openwrt-glmain/firewall.batch   # the exact `uci -m import firewall` input
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
  `skyg_*`. It deletes existing `skyg_*` rules, adds the newly generated ones as real named
  UCI sections via `uci -m import firewall` (not `uci batch` — the generator's output is
  declarative `config rule 'name'` syntax, not batch commands), commits, and reloads — so
  deploys are idempotent and never clobber hand-written rules.
- **The LAN is one flat L2 bridge, not real per-network VLANs.** `apl`, `cam`, `lab`, etc. are
  just address-range conventions within a single `br-lan` (one `/16`, all ports bridged
  together). Because of this, unicast traffic between two hosts on the bridge is normally
  switched at L2 and never reaches the router's iptables FORWARD chain — so the `skyg_*`
  internet-only DROP rules would silently never fire. `skyg-apply.sh` works around this by
  enabling `net.bridge.bridge-nf-call-iptables` / `-ip6tables` (via a managed block appended
  to `/etc/sysctl.conf`, since `/etc/sysctl.d/*.conf` ships them disabled and is reset on
  firmware upgrades) so bridged traffic is actually filtered. Confirmed live: without this,
  an `internetOnly`-flagged device's DROP rule showed 0/0 packet/byte counters in
  `iptables -L -v -n` despite matching traffic; with it enabled, blocking works as expected.
