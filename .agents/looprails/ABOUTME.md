# .agents/looprails

Looprail files for this repo.

## journal-triage

`journal-triage.toml` reads the journald log of this machine, has Claude Opus triage it
against this repo, and writes a report ranked by urgency to `.tmp/journal-reports/<host>-<date>.md` (gitignored).

- `journal-triage/collect.sh`: pulls warnings (and worse), failed units and a digest of
  unique messages into the run folder.
- `journal-triage/triage.md`: the brief for Opus. It reads `GUIDELINES.md`, traces each issue to
  `hosts/<host>/` or `modules/`, and suggests fixes as repo changes. It only reads and suggests:
  no edits, no builds, no sudo.
- Inputs: `since` (default `24 hours ago`), `priority` (`err`, `warning`, `notice`),
  `host` (default `fwbook`), `repo` (default `/home/ari/nixos-setup`).

Run: `looprail run .agents/looprails/journal-triage.toml`, or ask the agent to run it.

## flake-input-review

From the repository root, run `looprail run flake-input-review '{"input":"nixpkgs-unstable"}'`.
Use any direct input in `flake.nix`. The name `nixpkgs-stable` selects `nixpkgs`.

The resolve step uses Nix to update the selected input in a temporary copy of the flake
declaration and lockfile. For a changed graph, the gather step samples public upstream evidence
and searches local configuration. One Claude Opus step assesses affected hosts, fixed issues,
possible regressions, live activation and boot. A shell step renders `flake-input-review.html`
in the Looprail run directory and returns its absolute path. An unchanged or unresolved input
goes directly to HTML. A resolution failure yields an unknown verdict.

Requires Nix with flakes, Python 3, ripgrep, and claude-agent-acp. Looprail checks the agent harness at startup.
Upstream resolution uses the caller's existing network access and credentials. Coverage and
unverified runtime behavior are recorded in the report.
