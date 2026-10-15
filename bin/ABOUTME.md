# bin/

The `skyg` CLI — the single entry point for all system management tasks in this repo.

## Structure

```
bin/
├── skyg                    # Bash shim: exec nu --commands "use lib/cmds.nu *; skyg $*"
├── check-flake-versions    # Bash shim for `skyg flake check-versions`
├── temp-monitor            # NuShell script: collect CPU/GPU temps to CSV + optional graph
├── TEMP_MONITOR_README.md  # Usage docs for temp-monitor
└── lib/
    ├── cmds.nu        # Dispatcher + bare `skyg` + `skyg profiles` + deprecated aliases
    ├── os.nu          # `skyg os` (local NixOS rebuild/switch/rollback)
    ├── remote.nu      # `skyg remote *` (deploy, install, boot-all, status, reboot-pending)
    ├── secrets.nu     # `skyg secrets list/show/edit/compare`
    ├── ca.nu          # `skyg ca init/issue`
    ├── pkgs.nu        # `skyg pkgs update`
    ├── flake.nu       # `skyg flake update/check/check-versions`
    ├── build.nu       # `skyg build image/openwrt`
    ├── render.nu      # `skyg render html-tpl`
    ├── hm.nu          # `skyg hm <action>`
    ├── helpers.nu     # Shared helpers: REPO_ROOT const + internal functions
    ├── profile.nu     # Profile helpers and tab-completion data
    ├── types.nu       # Tab-completion completer functions
    └── remote.utils.nu # Remote-specific helpers (boot info, wait-for-host, notify)
```

## Key Commands

| Command                                    | Description                                                                                                                                                                                                                                                         |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skyg os switch`                           | Rebuild and switch local system                                                                                                                                                                                                                                     |
| `skyg os rollback`                         | Roll back to previous generation                                                                                                                                                                                                                                    |
| `skyg remote switch <host>`                | Deploy to a remote host                                                                                                                                                                                                                                             |
| `skyg remote install <host>`               | Fresh-install a remote host via nixos-anywhere, using `hosts/<profile>.disko.nix`. Always wipes the disks in that file. Aborts if the file is missing, if the host already boots NixOS from disk (unless `--force-wipe`), or if you do not type the short hostname. |
| `skyg remote status <host>`                | Check status of a single remote host                                                                                                                                                                                                                                |
| `skyg remote status --all`                 | Check status of all remote hosts                                                                                                                                                                                                                                    |
| `skyg remote boot-all`                     | Boot all remote hosts                                                                                                                                                                                                                                               |
| `skyg remote reboot-pending`               | Reboot every remote host with a pending reboot (`booted-system` != `current-system`). Lists them, asks for confirmation, then reboots one at a time, waiting for each to come back online and sending a desktop notification when it does.                          |
| `skyg hm switch`                           | Apply Home Manager config                                                                                                                                                                                                                                           |
| `skyg flake update [input]`                | Update flake inputs                                                                                                                                                                                                                                                 |
| `skyg flake check`                         | Run `nix flake check --no-build`                                                                                                                                                                                                                                    |
| `skyg flake check-versions`                | Verify NixOS release version consistency in flake.nix                                                                                                                                                                                                               |
| `skyg build image iso\|pi1\|pi2`           | Build bootable image — ISO (`iso`) or Pi SD card image (`pi1`, `pi2`)                                                                                                                                                                                               |
| `skyg build openwrt [router]`              | Deploy OpenWrt config                                                                                                                                                                                                                                               |
| `skyg profiles`                            | List valid local/remote profiles                                                                                                                                                                                                                                    |
| `skyg secrets list`                        | List known secret names                                                                                                                                                                                                                                             |
| `skyg secrets show <secret>`               | Decrypt a secret to `.tmp/unencrypted-<secret>`                                                                                                                                                                                                                     |
| `skyg secrets edit <secret> [--yaml]`      | Encrypt a working copy back into the secret                                                                                                                                                                                                                         |
| `skyg secrets compare <secret>`            | Diff the working copy against the stored secret                                                                                                                                                                                                                     |
| `skyg ca init`                             | Generate the lab root CA: key → `secrets/lab-ca-key.age`, cert → `configs/pki/lab-ca.crt` (see `configs/pki/ABOUTME.md`)                                                                                                                                            |
| `skyg ca issue <domain> --for <host>`      | Mint a TLS leaf cert signed by the lab CA: cert → `configs/pki/<domain>.crt`, key → `secrets/<name>-tls-key.age`. Auto-registers missing `secrets.nix` entries.                                                                                                     |
| `skyg pkgs update [--all\|<pkg>]`          | Update one or all custom packages                                                                                                                                                                                                                                   |
| `skyg render html-tpl <file>`              | Render a Gitea `.tmpl` and serve it on `127.0.0.1` for preview. Foreground — Ctrl+C to stop. `<file>` tab-completes from `**/*.tmpl`.                                                                                                                               |

## Agent Note

> **Never invoke `skyg` commands that trigger builds or switches.**
> Only the user runs these. Edits to `cmds.nu` / `remote.nu` are safe if the user asks for CLI changes.
