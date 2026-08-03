#!/usr/bin/env bash
# Classification and removal for teardown-worktrees.
#
# Usage: teardown.sh classify [all]
#          List this repo's wt/ worktrees. Default scope: current effort
#          (wt/<current-feature-slug>/*). 'all' sweeps every wt/* worktree.
#          Output: WORKTREE|<branch>|<path>|<merged|unmerged>|<clean|dirty>|<workspace-id-or-none>
#
#        teardown.sh remove <path> <branch> delete-branch|keep-branch
#          Remove one worktree checkout. delete-branch also deletes the branch
#          (refuses unless merged into HEAD: safe by construction).
#          keep-branch removes the checkout only, forcing past dirty state
#          (caller must have obtained explicit human confirmation first).
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode="${1:-}"

case "$mode" in
  classify)
    scope="${2:-current}"
    if [ "$scope" = "all" ]; then prefix="$BRANCH_PREFIX/"
    else prefix="$BRANCH_PREFIX/$(feature_slug)/"; fi
    git worktree list --porcelain | awk '
      /^worktree / { path = substr($0, 10) }
      /^branch /   { sub("refs/heads/", "", $2); print $2 "|" path }' | \
    while IFS='|' read -r branch path; do
      case "$branch" in
        "$prefix"*) ;;
        *) continue ;;
      esac
      if git merge-base --is-ancestor "$branch" HEAD 2>/dev/null; then merged=merged; else merged=unmerged; fi
      if [ -z "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then clean=clean; else clean=dirty; fi
      ws="$(herdr_workspace_for_path "$path")"
      printf 'WORKTREE|%s|%s|%s|%s|%s\n' "$branch" "$path" "$merged" "$clean" "${ws:-none}"
    done
    ;;

  remove)
    path="${2:-}"; branch="${3:-}"; branch_mode="${4:-}"
    [ -n "$path" ] && [ -n "$branch" ] || err "usage: teardown.sh remove <path> <branch> delete-branch|keep-branch"
    case "$branch_mode" in delete-branch|keep-branch) ;; *) err "last arg must be delete-branch or keep-branch" ;; esac

    if [ "$branch_mode" = "delete-branch" ]; then
      git merge-base --is-ancestor "$branch" HEAD 2>/dev/null || \
        err "refusing delete-branch: '$branch' is not merged into HEAD. Use keep-branch, or merge first."
      [ -z "$(git -C "$path" status --porcelain 2>/dev/null)" ] || \
        err "refusing delete-branch: worktree '$path' has uncommitted changes. Use keep-branch, or clean it first."
    fi

    # Close the Herdr workspace first so no pane holds the directory open.
    ws="$(herdr_workspace_for_path "$path")"
    if [ -n "$ws" ]; then
      herdr worktree remove --workspace "$ws" --force --json >/dev/null 2>&1 || true
    fi
    # Ensure the checkout is gone even if Herdr had nothing open for it.
    if git worktree list --porcelain | grep -Fxq "worktree $path"; then
      git worktree remove --force "$path"
    fi
    git worktree prune
    ok "removed worktree $path"

    if [ "$branch_mode" = "delete-branch" ] && git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
      git branch -D "$branch"   # -D is safe: merged-ness was proven above
      ok "deleted branch $branch"
    else
      info "kept branch $branch"
    fi
    ;;

  *)
    err "usage: teardown.sh classify [all] | teardown.sh remove <path> <branch> delete-branch|keep-branch"
    ;;
esac
