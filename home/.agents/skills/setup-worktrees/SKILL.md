---
name: setup-worktrees
description: Slice a predefined body of work into parallel git worktrees, one Herdr workspace and staged agent per unit, wave-gated by dependencies.
disable-model-invocation: true
---

Slice predefined work (a spec, issue, tickets, or the conversation) into parallel worktrees: one Herdr workspace per unit, each with a briefed agent staged and waiting for a human "begin". Agent-agnostic by design: everything runs through Herdr's uniform agent CLI and git; no Claude-specific conventions anywhere.

Naming is derived, never invented: branch `wt/<feature-slug>/<unit-slug>`, path `~/.herdr/worktrees/<repo>-<unit-slug>`, workspace/tab/agent label `<unit-slug>`. The derivation lives in `scripts/lib.sh` and nowhere else. Rerunning this skill is the recovery path for partial setups and the launch path for later waves: scripts skip what already matches the derivation and stop on anything that contradicts it.

## Steps

### 1. Analyze

Read the work source (argument, linked document, or conversation). Decompose into units. Done when every unit has: scope, dependency edges to other units, shared-file conflict points, and a checkable completion criterion, with no part of the source work left unassigned.

### 2. Strategy

Offer 2-3 worktree strategies at different delegation levels (one worktree fully delegated / cohesive units / fine-grained), never proposing more worktrees than the dependency structure can usefully support. Explain tradeoffs, recommend one, and let the user choose. If the decomposition is a single unit or strictly serial, say so and skip straight to the plan with one worktree; do not present fake alternatives.

Group units into waves: wave 1 has no unresolved dependencies; a unit whose dependency has not yet landed belongs to a later wave. Soft conflicts (two units touching the same file, neither needing the other's output) may share a wave with an explicit coordination note in each briefing.

### 3. Plan

Ask which agent kind is the run default, then present the full plan in conversation: per unit its slug, wave, branch, path, agent kind (per-unit overrides welcome), briefing summary, and completion criterion. Done when the user explicitly approves. Nothing is created before this gate.

### 4. Preflight

Run `scripts/preflight.sh <unit-slug>...` for all wave-1 units. It resolves one base SHA for the whole run and scans for collisions.

- `DIRTY` lines: show the user the files and state plainly that they will NOT be in the worktrees; wait for go/no-go.
- `CANDIDATE` lines: propose the copy list (`.env`-family pre-selected); the user confirms which files each worktree receives.
- `EXISTS` lines: that unit is already (partly) provisioned; provision will finish it.
- `ERROR`: relay the message and stop; every error names its fix.

### 5. Provision

Write each unit's briefing to a temp file, containing: the overall objective, this unit's scope, its dependencies and what it must NOT touch (files and responsibilities owned by other units), its completion criterion, and how to verify it. Then, per unit in plan order:

```sh
scripts/provision.sh --unit <slug> --kind <kind> --base <BASE_SHA> \
  --briefing <file> [--copy <path>]...
```

The script is idempotent: worktree -> copies -> BRIEFING.md (git-excluded) -> two tabs (tab `agent` hosts the agent, tab `shell` is a plain shell at the worktree root) -> agent start -> staging prompt telling the agent to read BRIEFING.md, reply with a summary, and wait for a human before beginning. Done when every wave-1 unit prints `PROVISIONED`.

### 6. Verify

Run `scripts/verify.sh --unit <slug> --kind <kind>` for every provisioned unit. On FAIL lines, consult `HERDR.md`, repair, and re-verify. Done when every unit passes every check.

### 7. Summary

Present a table: unit -> branch -> worktree path -> workspace -> agent kind and status, plus deferred later-wave units and which dependency each waits on. Remind the user: review each agent's summary in its workspace, then tell it to begin; when a wave's branches are merged, rerun this skill for the next wave (new worktrees branch from the then-current HEAD, briefed against the merged reality).
