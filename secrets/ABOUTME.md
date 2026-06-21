# secrets/

Age-encrypted secret files managed with [agenix](https://github.com/ryantm/agenix).

## Contents

| File | Description |
|---|---|
| `dns-addresses.conf.age` | DNS address overrides for the dnsmasq module |
| `glmain.json.age` | OpenWrt router credentials/config for `glmain` |

## ⚠️ Agent Warning

**Do not read, write, decrypt, or delete any `.age` file.**
These files are encrypted and can only be decrypted by authorized SSH keys.
Editing them outside of `agenix` will corrupt the secret.

## Workflow (for humans)

```bash
# Edit a secret (decrypts, opens editor, re-encrypts)
skyg secrets edit dns-addresses.conf.age

# Re-key all secrets (e.g. after adding a new host key)
skyg secrets rekey
```

## Adding a New Secret

1. Add the `.age` filename and authorized public keys to `secrets.nix`
2. Run `skyg secrets edit <name>.age` to create and encrypt the file
3. Reference it in a module via `config.age.secrets.<name>.path`

See `docs/agenix.md` for the full workflow reference.
