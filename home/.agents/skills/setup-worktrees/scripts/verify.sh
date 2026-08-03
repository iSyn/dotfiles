#!/usr/bin/env bash
# Read-only verification of one provisioned unit against its derived state.
#
# Usage: verify.sh --unit <slug> --kind <agent-kind>
#
# Prints PASS/FAIL per check; exit 0 only if every check passes.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

unit="" kind=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --unit) unit="$2"; shift 2 ;;
    --kind) kind="$2"; shift 2 ;;
    *) err "unknown argument: $1" ;;
  esac
done
[ -n "$unit" ] && [ -n "$kind" ] || err "usage: verify.sh --unit <slug> --kind <agent-kind>"

branch="$(derive_branch "$unit")"
path="$(derive_path "$unit")"
fails=0
check() { # $1 = label, $2 = shell expression to evaluate
  if eval "$2" >/dev/null 2>&1; then printf 'PASS|%s|%s\n' "$unit" "$1"
  else printf 'FAIL|%s|%s\n' "$unit" "$1"; fails=$((fails+1)); fi
}

check "branch $branch exists"        "git rev-parse --verify --quiet 'refs/heads/$branch'"
check "worktree dir exists"          "[ -d '$path' ]"
check "git worktree registered"      "git worktree list --porcelain | grep -Fxq 'worktree $path'"
check "worktree is on $branch"       "[ \"\$(git -C '$path' rev-parse --abbrev-ref HEAD)\" = '$branch' ]"
check "BRIEFING.md present"          "[ -f '$path/BRIEFING.md' ]"
check "BRIEFING.md git-excluded"     "! git -C '$path' status --porcelain | grep -q 'BRIEFING.md'"
check "staging prompt submitted"     "[ -f \"\$(git -C '$path' rev-parse --path-format=absolute --git-dir)/wt-staged\" ]"

workspace_id="$(herdr_workspace_for_path "$path")"
check "herdr workspace open"         "[ -n '$workspace_id' ]"

if [ -n "$workspace_id" ]; then
  tabs="$(herdr_tabs_in_workspace "$workspace_id")"
  tab_count="$(printf '%s\n' "$tabs" | grep -c .)"
  tab_labels="$(printf '%s\n' "$tabs" | cut -d'|' -f2 | sort | paste -sd, -)"

  pane_report="$(hj "
panes = sorted((p for p in j.get('panes', []) if p.get('workspace_id') == '$workspace_id'), key=lambda p: p['pane_id'])
print(len(panes))
for p in panes:
    print((p.get('cwd') or '') + '|' + (p.get('agent') or '') + '|' + (p.get('agent_status') or ''))
" pane list)"
  pane_count="$(printf '%s\n' "$pane_report" | head -1)"
  agent_line="$(printf '%s\n' "$pane_report" | tail -n +2 | awk -F'|' '$2 != ""' | head -1)"
  agent_kind="$(printf '%s' "$agent_line" | cut -d'|' -f2)"
  agent_status="$(printf '%s' "$agent_line" | cut -d'|' -f3)"
  bad_cwd="$(printf '%s\n' "$pane_report" | tail -n +2 | awk -F'|' -v want="$path" '$1 != want' | grep -c . )"

  check "exactly 2 tabs (got $tab_count)"            "[ '$tab_count' = '2' ]"
  check "tabs labeled agent,shell (got $tab_labels)" "[ '$tab_labels' = 'agent,shell' ]"
  check "one pane per tab (got $pane_count panes)"   "[ '$pane_count' = '2' ]"
  check "both panes cwd at worktree"                 "[ '$bad_cwd' = '0' ]"
  check "agent pane exists"                          "[ -n '$agent_line' ]"
  check "agent kind is $kind (got ${agent_kind:-none})" "[ '$agent_kind' = '$kind' ]"
  check "agent live (status: ${agent_status:-none})" "[ '$agent_status' = 'idle' ] || [ '$agent_status' = 'working' ] || [ '$agent_status' = 'done' ]"
fi

if [ "$fails" -eq 0 ]; then ok "unit '$unit' fully verified"; exit 0
else printf 'ERROR: unit %s: %s check(s) failed\n' "$unit" "$fails" >&2; exit 1; fi
