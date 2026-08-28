# secrets/

Age-encrypted secret files managed with [agenix](https://github.com/ryantm/agenix).

## Contents

| File | Description |
|---|---|
| `dns-addresses.conf.age` | DNS address overrides for the dnsmasq module |
| `glmain.json.age` | OpenWrt router credentials/config for `glmain` |
| `hermes-env.age` | Hermes agent env vars (fwbook + fwdesk) |
| `hermes-env` | Unencrypted working copy of `hermes-env.age` |
| `iu-project.age` | iu-project credentials (minipc1) |
| `portainer-agent-bigbox1.age` | Portainer agent env vars (bigbox1) |
| `stack1.age` | Compose definition for stack1 (minipc2) |
| `stack2.age` | Compose definition for stack2 (minipc2) |

The authoritative list of names + authorized keys is `secrets.nix` in the repo root.

## ⚠️ Agent Warning

**Do not read, write, decrypt, or delete any `.age` file.**
These files are encrypted and can only be decrypted by authorized SSH keys.
Editing them outside of `agenix` will corrupt the secret.

## Workflow (for humans)

```bash
# List known secret names
skyg secrets

# Decrypt a secret for editing (writes .tmp/unencrypted-<name>)
skyg decrypt dns-addresses.conf

# Re-encrypt after editing (reads .tmp/unencrypted-<name> by default)
skyg encrypt dns-addresses.conf

# Verify your working copy matches the stored secret
skyg compare-secret dns-addresses.conf
```

**Re-keying** (e.g. after adding a host key to `secrets.nix`): there is no bulk
re-key command — for each affected secret run `skyg decrypt <name>` followed by
`skyg encrypt <name>` to re-encrypt it against the updated key set.

## Adding a New Secret

1. Add the `.age` filename and authorized public keys to `secrets.nix`
2. Create the plaintext in `.tmp/unencrypted-<name>` (or pass `--source <file>`) and run
   `skyg encrypt <name>` (add `--yaml` to validate YAML before encrypting)
3. Reference it in a module via `config.age.secrets.<name>.path`

See `docs/agenix.md` for the full workflow reference.
