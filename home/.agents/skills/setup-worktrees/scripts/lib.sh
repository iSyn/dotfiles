# Shared naming derivation and Herdr JSON helpers for setup/teardown-worktrees.
# Single source of truth: every script derives names through these functions,
# so a rerun always computes identical branches, paths, and labels.

WORKTREE_ROOT="${HOME}/.herdr/worktrees"
BRANCH_PREFIX="wt"

slugify() {
  # lowercase; any run of non-alphanumerics becomes one dash; trim edge dashes
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

repo_root()   { git rev-parse --show-toplevel; }
repo_name()   { basename "$(repo_root)"; }
feature_slug() { slugify "$(git rev-parse --abbrev-ref HEAD)"; }

derive_branch() { # $1 = unit slug
  printf '%s/%s/%s' "$BRANCH_PREFIX" "$(feature_slug)" "$1"
}

derive_path() { # $1 = unit slug
  printf '%s/%s-%s' "$WORKTREE_ROOT" "$(repo_name)" "$1"
}

# herdr CLI wrappers return single-line JSON; parse with python3 (herdr's own
# integrations already depend on python3 being present).
hj() { # hj '<python expr over parsed json as j>' <herdr args...>
  local expr="$1"; shift
  herdr "$@" | python3 -c "
import json, sys
j = json.load(sys.stdin)
if 'error' in j:
    sys.stderr.write('herdr error: ' + json.dumps(j['error']) + '\n')
    sys.exit(1)
j = j.get('result', j)
$expr"
}

# The Herdr server resolves the target repo from its focused workspace, NOT
# from this shell's cwd; every worktree command must pass --cwd explicitly.
herdr_workspace_for_path() { # $1 = worktree path -> workspace id or empty
  hj "
for w in j.get('worktrees', []):
    if w.get('path') == '$1' and w.get('open_workspace_id'):
        print(w['open_workspace_id']); break
" worktree list --cwd "$(repo_root)" --json
}

herdr_panes_in_workspace() { # $1 = workspace id -> pane ids, one per line, id-sorted
  hj "
panes = [p['pane_id'] for p in j.get('panes', []) if p.get('workspace_id') == '$1']
print('\n'.join(sorted(panes)))
" pane list
}

herdr_tabs_in_workspace() { # $1 = workspace id -> 'tab_id|label' lines, ordered by tab number
  hj "
tabs = sorted((t for t in j.get('tabs', []) if t.get('workspace_id') == '$1'), key=lambda t: t.get('number', 0))
print('\n'.join(t['tab_id'] + '|' + str(t.get('label','')) for t in tabs))
" tab list
}

herdr_pane_in_tab() { # $1 = tab id -> first pane id in that tab
  hj "
panes = sorted(p['pane_id'] for p in j.get('panes', []) if p.get('tab_id') == '$1')
print(panes[0] if panes else '')
" pane list
}

herdr_agent_pane_in_workspace() { # $1 = workspace id -> pane id hosting an agent, or empty
  hj "
for a in j.get('agents', []):
    if a.get('workspace_id') == '$1':
        print(a['pane_id']); break
" agent list
}

err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'INFO: %s\n' "$*"; }
ok() { printf 'OK: %s\n' "$*"; }
skip() { printf 'SKIP: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; }
