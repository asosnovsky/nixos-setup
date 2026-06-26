# modules/home/

The Home Manager layer. **Unlike the rest of the repo, these files are not NixOS modules** —
they are plain functions that return Home Manager attribute sets. `core/user.nix` imports
this directory and calls the exported builders to populate `home-manager.users.<name>`.

## Files

```
home/
├── default.nix     # Exports makeRootUser and makeCommonUser; composes the modules below
├── programs.nix    # programs.* — shell + CLI tooling (zsh, nushell, neovim, starship, …)
├── services.nix    # services.* — gpg-agent with SSH support
├── git.nix         # makeCommonGitConfigs — git/delta config + includes from gitconfigs/
├── fonts.nix       # fontconfig default font families
└── gitconfigs/     # Raw .gitconfig fragments included by every user (aliases, …)
```

## Entry points

`default.nix` exports two builder functions, both consumed by `core/user.nix`:

- `makeRootUser { hostName }` — minimal root profile (jq, kubectl, btop, …) with a
  `root@<hostName>` git identity.
- `makeCommonUser { name, fullName, email, extraGitConfigs ? [] }` — the full human profile:
  dev packages, the shared shell/program config, and the user's git identity.

Both apply the shared `homeModule` (state version + shell aliases like `cat→bat`,
`ls→eza`, `du→dust`, `df→duf`), `programsModule`, `servicesModule`, and `fontsModule`.

## Notable details

- **Shells**: zsh is the login shell, with autosuggestions, syntax highlighting, and a
  `notify-send` hook for long-running commands. Nushell, starship, carapace, zellij, and
  tmux are all configured here.
- **Git** (`git.nix`): `makeCommonGitConfigs` auto-includes every file under `gitconfigs/`
  plus any per-user `extraGitConfigs`. Uses delta for diffs.
- The standalone (non-NixOS) Home Manager path in `modules/lib.nix`
  (`makeHomeManagerUsers`) also calls `makeCommonUser`.

## Conventions

- These are **functions, not modules** — there is no `options`/`config`/`lib.mkIf` here.
  Keep that pattern; the NixOS module system is applied one level up in `core/user.nix`.
- Add new shared CLI programs to `programs.nix`, services to `services.nix`, and global
  packages to the relevant `home.packages` list in `default.nix`.
