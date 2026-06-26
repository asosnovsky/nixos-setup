# modules/home/gitconfigs/

Raw git config fragments that are auto-included into every user's `~/.gitconfig`.

`modules/home/git.nix` reads every **non-directory** file in this folder and adds it as a
`git.includes` path, so any file dropped here is picked up automatically — no wiring needed.

## Files

```
gitconfigs/
└── alias.conf   # [alias] block: pp, up, ca, cap, undo-commit, sync, clean-branches, …
```

## Conventions

- Each file is a standalone git config fragment (e.g. an `[alias]` section). Drop a new
  `.conf` file here and it is included on the next switch.
- Keep these provider-agnostic and identity-free; user name/email come from
  `skyg.user.{fullName,email}` via `makeCommonGitConfigs`.
