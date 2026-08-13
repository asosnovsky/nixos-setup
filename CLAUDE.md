# Claude Instructions — nixos-setup

**MANDATORY FIRST ACTION:** Read [`GUIDELINES.md`](GUIDELINES.md) in full before
doing anything in this repository. It is the single source of truth for agent
behavior here.

Key non-negotiable rules from that file:

- **Always present a plan first** and wait for user approval before making any
  changes — no matter how small the task.
- **Never run builds or system switches** (`nixos-rebuild`, `nh os`, `skyg os`,
  `nix build`, `nix flake check`, etc.) — zero exceptions, even if asked.
- Never edit `flake.lock`, `*.hardware-configuration.nix`, or anything in
  `secrets/`.
- Never add `imports = [...]` to host files.
- Never commit or create branches unless explicitly asked.
- Also read [`.agents/Agent.md`](.agents/Agent.md) for full repository context.
