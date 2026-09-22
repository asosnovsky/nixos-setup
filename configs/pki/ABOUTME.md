# configs/pki/

Public certificates of the lab internal CA. **Public material only** — private
keys live encrypted in `secrets/` (`lab-ca-key.age`, `<name>-tls-key.age`),
managed with agenix.

## Contents

| File           | Description                                                                                                          |
| -------------- | -------------------------------------------------------------------------------------------------------------------- |
| `lab-ca.crt`   | Root CA cert (`CN=Skyg Lab CA`). Trusted fleet-wide via `modules/core/lab-ca.nix` (`security.pki.certificateFiles`). |
| `lab-ca.srl`   | OpenSSL serial counter, written on first `ca issue`. Needed for unique serials — commit it.                          |
| `<domain>.crt` | Leaf certs issued for services (e.g. `buzz.app.internal.crt`).                                                       |

## Managed by `skyg ca` (bin/lib/cmds.nu)

```sh
skyg ca init                                  # one-time: generate the root CA
skyg ca issue buzz.app.internal --for minipc1 # mint a leaf for a service
```

- `ca init` encrypts the CA key to `secrets/lab-ca-key.age` (recipient: `ari`
  only) and writes `lab-ca.crt` here. Refuses to overwrite an existing CA.
- `ca issue` decrypts the CA key to `.tmp/`, signs a leaf (SAN = domain, EKU
  serverAuth, 825 days), encrypts the leaf key to `secrets/<name>-tls-key.age`
  (recipients: `ari` + the `--for` host), and writes `<domain>.crt` here.
- Both commands auto-register missing entries in `secrets.nix` — review with
  `git diff` after running them.

Never hand-edit or commit keys here. Re-issuing: delete the leaf cert and
re-run `ca issue`. Rotating the CA itself: delete `lab-ca.crt` +
`secrets/lab-ca-key.age`, re-run `ca init`, re-issue all leaves, and rebuild
every host (fleet trust comes from the committed root cert).

## When to use what

- **Lab CA (this dir)**: internal-only services whose clients all use the
  system trust store (fleet trust via `modules/core/lab-ca.nix`).
- **Public Let's Encrypt cert** (`skyg.server.acme`, see
  `modules/nixos/server/acme/`): anything reached by clients that only trust
  public CAs — e.g. the Buzz desktop app, whose WS client bundles Mozilla
  roots and ignores the system store. Buzz uses a public cert for
  `buzz.home.sosnovsky.ca` (Cloudflare DNS-01); the zone lives in
  `~/Projects/Homelab/homelab` pending migration into this repo.
  `buzz.app.internal.crt` here is now unused by the buzz stack and kept only
  as a lab-CA example.
