# Guidelines — modules/home/

Conventions specific to the Home Manager layer. Read alongside the repo-root `GUIDELINES.md`.

---

## ⚠️ These are functions, not NixOS modules

The biggest gotcha in this directory: the files here are **plain Nix functions that return
attribute sets**, not `{ config, lib, ... }` modules. There is no `options`, no `config`
block, and no `lib.mkIf`.

- `default.nix` exports `makeRootUser` and `makeCommonUser`.
- `programs.nix`, `services.nix`, `git.nix`, `fonts.nix` each export a value/function that
  `default.nix` composes.
- The NixOS/HM module system is applied **one level up**, in `modules/core/user.nix`, which
  feeds the result into `home-manager.users.<name>`.

Do **not** convert these into module-style files or add `skyg.*` options here — that belongs
in `core/user.nix`.

## Where to add things

| You want to add… | Put it in |
|---|---|
| A shared CLI program (`programs.<x>`) | `programs.nix` |
| A user service (`services.<x>`) | `services.nix` |
| A package for all users | `home.packages` in `default.nix` (`makeCommonUser`) |
| A package for root only | `home.packages` in `makeRootUser` |
| A git alias / git config fragment | a new file in `gitconfigs/` (auto-included) |
| A default font family | `fonts.nix` |

## Things to keep consistent

- **Identity flows in, not hardcoded.** `makeCommonUser` receives `name`/`fullName`/`email`
  from `skyg.user.*`. Don't hardcode a username or email here.
- **Root vs human user.** Keep root's profile minimal (admin/cluster tooling); put the full
  toolchain in `makeCommonUser`.
- **`makeCommonUser` is reused** by both the NixOS path (`core/user.nix`) and the standalone
  Home Manager path (`modules/lib.nix → makeHomeManagerUsers`). Changes affect both.
- **State version** comes from `skyg.home-manager.version`; don't pin a literal here.

## Validation

You cannot meaningfully build HM output without a full switch (which is forbidden — see root
`GUIDELINES.md`). Limit yourself to `nix-instantiate --parse` for syntax. The user validates
by running their switch command.
