# bin/

The `skyg` CLI — the single entry point for all system management tasks in this repo.

## Structure

```
bin/
├── skyg                    # Bash shim: exec nu --commands "use lib/cmds.nu *; skyg $*"
├── check-flake-versions    # Bash shim for `skyg check-flake-versions`
├── temp-monitor            # NuShell script: collect CPU/GPU temps to CSV + optional graph
├── TEMP_MONITOR_README.md  # Usage docs for temp-monitor
└── lib/
    ├── cmds.nu    # All subcommand implementations (NuShell — source of truth); commands only
    ├── helpers.nu # Shared helpers: REPO_ROOT const + internal functions used by commands
    ├── profile.nu # Profile helpers and tab-completion data
    └── types.nu   # Type definitions
```

## Key Commands

| Command                               | Description                                                                                                                                                                                                                                                         |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skyg os switch`                      | Rebuild and switch local system                                                                                                                                                                                                                                     |
| `skyg remote switch <host>`           | Deploy to a remote host                                                                                                                                                                                                                                             |
| `skyg remote install <host>`          | Fresh-install a remote host via nixos-anywhere, using `hosts/<profile>.disko.nix`. Always wipes the disks in that file. Aborts if the file is missing, if the host already boots NixOS from disk (unless `--force-wipe`), or if you do not type the short hostname. |
| `skyg hm switch`                      | Apply Home Manager config                                                                                                                                                                                                                                           |
| `skyg update [input]`                 | Update flake inputs                                                                                                                                                                                                                                                 |
| `skyg build-image iso                 | pi1                                                                                                                                                                                                                                                                 | pi2` | Build bootable image — ISO (`iso`) or Pi SD card image (`pi1`, `pi2`) |
| `skyg openwrt`                        | Deploy OpenWrt config                                                                                                                                                                                                                                               |
| `skyg rollback`                       | Roll back to previous generation                                                                                                                                                                                                                                    |
| `skyg profiles`                       | List valid local/remote profiles                                                                                                                                                                                                                                    |
| `skyg check`                          | Run `nix flake check --no-build`                                                                                                                                                                                                                                    |
| `skyg check-flake-versions`           | Verify NixOS release version consistency in flake.nix                                                                                                                                                                                                               |
| `skyg remote boot-all`                | Boot all remote hosts (builds on `fwdesk`)                                                                                                                                                                                                                          |
| `skyg remote status`                  | Check status of all remote hosts                                                                                                                                                                                                                                    |
| `skyg secrets`                        | List known secret names                                                                                                                                                                                                                                             |
| `skyg decrypt <secret>`               | Decrypt a secret to `.tmp/unencrypted-<secret>`                                                                                                                                                                                                                     |
| `skyg encrypt <secret> [--yaml]`      | Encrypt a working copy back into the secret                                                                                                                                                                                                                         |
| `skyg compare-secret <secret>`        | Diff the working copy against the stored secret                                                                                                                                                                                                                     |
| `skyg ca init`                        | Generate the lab root CA: key → `secrets/lab-ca-key.age`, cert → `configs/pki/lab-ca.crt` (see `configs/pki/ABOUTME.md`)                                                                                                                                            |
| `skyg ca issue <domain> --for <host>` | Mint a TLS leaf cert signed by the lab CA: cert → `configs/pki/<domain>.crt`, key → `secrets/<name>-tls-key.age`. Auto-registers missing `secrets.nix` entries.                                                                                                     |

## Agent Note

> **Never invoke `skyg` commands that trigger builds or switches.**
> Only the user runs these. Edits to `cmds.nu` are safe if the user asks for CLI changes.
