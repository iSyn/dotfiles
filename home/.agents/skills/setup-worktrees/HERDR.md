# Herdr reference for worktree orchestration

Consulted by the provision/verify steps. The scripts in `scripts/` already encode all of this; read this file when a script fails and you need to diagnose or act manually.

## Object model

session -> **workspaces** -> **tabs** -> **panes**. A git worktree opens as a whole **workspace** (`herdr worktree create/open`), never as a bare tab. Agents are detected per pane with lifecycle states: `idle | working | blocked | done | unknown`.

**`idle` means "not typing", NOT "work complete".** An agent that finished, got stuck, or gave up all look idle. Never advance a dependency wave on agent state alone; a human judges done-ness.

## Commands the scripts use

```sh
herdr worktree create --branch <b> --base <sha> --path <p> --label <l> --no-focus --json
herdr worktree open   --path <p> --label <l> --no-focus --json   # existing worktree -> workspace
herdr worktree list --json      # .result.worktrees[]: branch, path, label, open_workspace_id, is_prunable
herdr worktree remove --workspace <id> [--force] --json

herdr workspace list            # .result.workspaces[]: workspace_id, label, tab_count, pane_count
herdr tab list                  # .result.tabs[]: tab_id, workspace_id, label, pane_count
herdr tab create --workspace <id> --cwd <p> --label <l> --no-focus
herdr tab rename <tab-id> <label>
herdr pane list                 # .result.panes[]: pane_id, workspace_id, tab_id, cwd, agent, agent_status

herdr agent start <name> --kind <kind> --pane <pane-id> --timeout 60000
herdr agent prompt <pane-id> "<text>" [--wait --until idle --timeout <ms>]
herdr agent wait <pane-id> --until idle --timeout <ms>
herdr agent read <pane-id> --lines <n>     # inspect what an agent replied
herdr agent list
```

All output is single-line JSON with either `result` or `error`. `herdr agent start --kind` accepts 20+ agent CLIs (claude, codex, gemini, opencode, cursor, amp, ...) and every command above behaves identically across them.

## Gotchas (all verified empirically)

- The server resolves the target repo from its **focused workspace**, not your shell's cwd: every `worktree` command must pass `--cwd <repo-root>` explicitly or it may act on the wrong repo. `lib.sh` and the scripts always do.
- The two-tab layout is not atomic: workspace arrives with 1 tab / 1 pane; the shell tab is a second `tab create` call. `verify.sh` catches partial results.
- `agent start` races the fresh pane's shell boot ("not an available shell"); `provision.sh` retries.
- `agent prompt` submitted before the agent's TUI is input-ready can sit unsubmitted in the input box. Always use `--wait --until working` on a staging prompt: a dropped submission returns `agent_prompt_stalled` instead of lying. (If a retry follows a drop, the leftover input text gets submitted along with the retry: cosmetic only.)
- `agent prompt --wait` does not track turns: if the agent is already working, the wait can match the wrong turn's completion. Only trust it on a freshly started agent.
- `agent prompt` targets accept pane ids; prefer pane ids over names (names can collide).
- `worktree create`/`remove` can leave a workspace open for the **source** checkout; after teardown, check `workspace list` and close strays.
- Worktree directory convention: `~/.herdr/worktrees/<repo>-<unit-slug>`, always passed explicitly via `--path` so the skill does not depend on the `[worktrees] directory` config value.
- Herdr copies nothing into new worktrees; untracked-file copying is this skill's own step.
