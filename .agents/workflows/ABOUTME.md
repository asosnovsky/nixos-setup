# .agents/workflows

nbot-wf workflow files for this repo.

## journal-triage

`journal-triage.toml` reads the journald log of this machine, has Claude Opus triage it
against this repo, and writes a report ranked by urgency to `~/journal-reports/<host>-<date>.md`.

- `journal-triage/collect.sh`: pulls warnings (and worse), failed units and a digest of
  unique messages into the run folder.
- `journal-triage/triage.md`: the brief for Opus. It reads `GUIDELINES.md`, traces each issue to
  `hosts/<host>/` or `modules/`, and suggests fixes as repo changes. It only reads and suggests:
  no edits, no builds, no sudo.
- Inputs: `since` (default `24 hours ago`), `priority` (`err`, `warning`, `notice`),
  `host` (default `fwbook`), `repo` (default `/home/ari/nixos-setup`).

Run: `nbot-wf run .agents/workflows/journal-triage.toml`, or ask the agent to run it.
