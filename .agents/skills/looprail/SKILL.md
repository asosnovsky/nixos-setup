---
name: looprail
description: When anything to do with looprails comes up, use the looprail MCP tools; if they are not available, run looprail install and restart the session.
---

When anything to do with looprails comes up, use the looprail MCP tools; if they are not available, run `looprail install` and restart the session.

The `get_looprail_guide` tool explains how to find, run, watch, answer, stop, resume, write and update a looprail.

Before you call a `looprail` command you have not used, read its schema first: call `get_looprail_cli` with that command (the resource `looprail://cli` holds every command), or run `looprail help --json <command>` when the MCP tools are not available. It gives the command's arguments, flags, exit codes and the shape of its `--json` output.

## Report progress while a run goes

`start_looprail` returns after a few seconds, long before the run ends, so the run is yours to follow and report. Do not go quiet until it ends. Every status answer starts with `## Show the user`, the part to show the user after each call, and ends with `## Next`, the one call to make next: follow it.

- Tell the user the run started: the looprail, its `run_id` and its inputs.
- Follow it with the call `## Next` gives: `get_looprail_status` with `wait_seconds` 60 to 120 (5 when left out, at most 300), not a quick polling loop. After each wait, show the user the steps as a table copied from the status's `Steps:` table: Step, Status, Elapsed, Model (which model runs an agent step), Tokens (input and output tokens spent, and the context of a running turn), Brief (a link to its brief file), Input and Output (the one-line summaries), with `-` where a step has none, and the `Tokens spent:` total line and the `Changes:` line (the lines the run's agents added and removed, and how many files they read) under it. Under it, say in a line or two what changed: the steps that finished, the step now running and any output that matters.
- In Claude Code, `looprail install` adds a status line and a PostToolUse hook that show the user each run's progress after every looprail tool call. With the hook installed you may leave out the full table after a wait and say only what changed; show the final table when the run ends.
- When the state is `needs_input` or `awaiting_inputs`, say what the run asks and answer with `provide_looprail_input` only if the user has already given you the answer; otherwise ask them.
- When it ends, report the state (`passed`, `failed`, `cancelled` or `interrupted`), the table with the outcome of each step and, on a failure, the step that failed and its last output. For `limited`, say when to resume.
- Report what the status says; never guess at a step's result.
