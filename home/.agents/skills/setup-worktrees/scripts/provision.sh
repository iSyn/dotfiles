#!/usr/bin/env bash
# Idempotent per-unit provisioning for setup-worktrees.
#
# Usage: provision.sh --unit <slug> --kind <agent-kind> --base <sha> \
#                     --briefing <file> [--copy <repo-relative-path>]...
#
# Sequence (each step skips when already satisfied, errors on contradiction):
#   worktree+workspace -> copy files -> BRIEFING.md -> two-tab layout
#   (agent tab + shell tab) -> agent start -> staging prompt
# Run preflight.sh first; this script trusts its collision scan.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

unit="" kind="" base="" briefing=""
copies=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --unit) unit="$2"; shift 2 ;;
    --kind) kind="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    --briefing) briefing="$2"; shift 2 ;;
    --copy) copies+=("$2"); shift 2 ;;
    *) err "unknown argument: $1" ;;
  esac
done
[ -n "$unit" ] && [ -n "$kind" ] && [ -n "$base" ] && [ -n "$briefing" ] || \
  err "usage: provision.sh --unit <slug> --kind <agent-kind> --base <sha> --briefing <file> [--copy <path>]..."
[ -f "$briefing" ] || err "briefing file not found: $briefing"

branch="$(derive_branch "$unit")"
path="$(derive_path "$unit")"

# 1. Worktree + workspace
if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
  git worktree list --porcelain | grep -Fxq "worktree $path" || \
    err "branch '$branch' exists without a worktree at '$path'; state contradicts derivation, run preflight.sh"
  skip "worktree $path (branch $branch) already exists"
else
  mkdir -p "$WORKTREE_ROOT"
  herdr worktree create --cwd "$(repo_root)" --branch "$branch" --base "$base" \
    --path "$path" --label "$unit" --no-focus --json >/dev/null || err "herdr worktree create failed for '$unit'"
  ok "created worktree $path on $branch from ${base:0:12}"
fi

workspace_id="$(herdr_workspace_for_path "$path")"
if [ -z "$workspace_id" ]; then
  herdr worktree open --cwd "$(repo_root)" --path "$path" --label "$unit" --no-focus --json >/dev/null || \
    err "worktree exists but no workspace is open for it and 'herdr worktree open' failed"
  workspace_id="$(herdr_workspace_for_path "$path")"
  [ -n "$workspace_id" ] || err "could not resolve a workspace for worktree '$path'"
  ok "opened workspace $workspace_id for existing worktree"
fi

# 2. Copy approved untracked files (copies, never symlinks)
for f in "${copies[@]:-}"; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || err "copy source missing: $f"
  if [ -e "$path/$f" ]; then
    skip "copy $f (already present in worktree)"
  else
    mkdir -p "$path/$(dirname "$f")"
    cp "$f" "$path/$f"
    ok "copied $f"
  fi
done

# 3. Briefing file, excluded via the repo-local ignore (never committed, never
#    touches the shared .gitignore)
if [ -f "$path/BRIEFING.md" ] && cmp -s "$briefing" "$path/BRIEFING.md"; then
  skip "BRIEFING.md already in place"
else
  cp "$briefing" "$path/BRIEFING.md"
  ok "wrote BRIEFING.md"
fi
exclude_file="$(git -C "$path" rev-parse --path-format=absolute --git-path info/exclude)"
mkdir -p "$(dirname "$exclude_file")"
grep -qxF '/BRIEFING.md' "$exclude_file" 2>/dev/null || echo '/BRIEFING.md' >> "$exclude_file"

# 4. Two-tab layout: tab 1 hosts the agent, tab 2 is a plain shell, both at
#    the worktree root
tabs="$(herdr_tabs_in_workspace "$workspace_id")"
tab_count="$(printf '%s\n' "$tabs" | grep -c . || true)"
case "$tab_count" in
  1)
    agent_tab="$(printf '%s\n' "$tabs" | head -1 | cut -d'|' -f1)"
    herdr tab create --workspace "$workspace_id" --cwd "$path" --label shell --no-focus >/dev/null
    ok "created shell tab"
    ;;
  2)
    agent_pane_existing="$(herdr_agent_pane_in_workspace "$workspace_id")"
    if [ -n "$agent_pane_existing" ]; then
      agent_tab="$(hj "
for p in j.get('panes', []):
    if p.get('pane_id') == '$agent_pane_existing':
        print(p['tab_id']); break
" pane list)"
    else
      agent_tab="$(printf '%s\n' "$tabs" | head -1 | cut -d'|' -f1)"
    fi
    skip "layout already has 2 tabs"
    ;;
  *)
    err "workspace $workspace_id has $tab_count tabs; expected 1 or 2. Close extras or tear down and rerun."
    ;;
esac

# 5. Stable tab names
herdr tab rename "$agent_tab" agent >/dev/null 2>&1 || true
agent_pane="$(herdr_pane_in_tab "$agent_tab")"
[ -n "$agent_pane" ] || err "no pane found in agent tab $agent_tab"

# 6. Agent, started bare (no agent-specific flags: stays model-agnostic)
if [ -n "$(herdr_agent_pane_in_workspace "$workspace_id")" ]; then
  skip "agent already running in workspace $workspace_id"
else
  # A fresh pane's shell may still be booting ("not an available shell"); retry.
  started=""
  for _ in 1 2 3 4 5 6; do
    if herdr agent start "$unit" --kind "$kind" --pane "$agent_pane" --timeout 60000 >/dev/null 2>&1; then
      started=yes; break
    fi
    sleep 2
  done
  [ -n "$started" ] || err "agent '$kind' failed to start in pane $agent_pane after retries"
  ok "started $kind agent '$unit'"
fi

# 7. Staging prompt: brief, summarize, then WAIT for a human. Marker file makes
#    this step idempotent across reruns.
marker="$(git -C "$path" rev-parse --path-format=absolute --git-dir)/wt-staged"
if [ -f "$marker" ]; then
  skip "staging prompt already sent"
else
  # --wait --until working proves the prompt actually landed: a submission the
  # agent's TUI silently dropped (input not ready yet) returns
  # agent_prompt_stalled instead, and we retry.
  landed=""
  for _ in 1 2 3; do
    if herdr agent prompt "$agent_pane" \
      "Read BRIEFING.md at the repository root. Reply with a short summary of the work assigned to you in this worktree and how you will verify completion. Then stop and wait. Do not begin implementation until a human explicitly tells you to begin." \
      --wait --until working --timeout 20000 >/dev/null 2>&1; then
      landed=yes; break
    fi
    sleep 3
  done
  [ -n "$landed" ] || err "staging prompt did not land in pane $agent_pane (agent never entered 'working'). Check the pane and rerun."
  touch "$marker"
  ok "staging prompt submitted"
fi

printf 'PROVISIONED|%s|%s|%s|%s|%s\n' "$unit" "$branch" "$path" "$workspace_id" "$agent_pane"
