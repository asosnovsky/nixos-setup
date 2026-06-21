# bin/

The `skyg` CLI — the single entry point for all system management tasks in this repo.

## Structure

```
bin/
├── skyg          # Bash shim: exec nu --commands "use lib/cmds.nu *; skyg $*"
└── lib/
    ├── cmds.nu   # All subcommand implementations (NuShell — source of truth)
    ├── profile.nu # Profile helpers and tab-completion data
    └── types.nu  # Type definitions
```

## Key Commands

| Command | Description |
|---|---|
| `skyg os switch` | Rebuild and switch local system |
| `skyg remote switch <host>` | Deploy to a remote host |
| `skyg hm switch` | Apply Home Manager config |
| `skyg update [input]` | Update flake inputs |
| `skyg build-iso` | Build bootable ISO |
| `skyg openwrt` | Deploy OpenWrt config |
| `skyg rollback` | Roll back to previous generation |

## Agent Note

> **Never invoke `skyg` commands that trigger builds or switches.**
> Only the user runs these. Edits to `cmds.nu` are safe if the user asks for CLI changes.
