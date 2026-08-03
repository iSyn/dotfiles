#!/usr/bin/env bash
# Read-only preflight for setup-worktrees.
#
# Usage: preflight.sh <unit-slug> [<unit-slug>...]
#
# Validates repo + Herdr state and scans for collisions on every name the
# given units would use. A unit whose branch/worktree already exist and match
# the derived names is reported EXISTS (rerun-safe: provision will skip or
# finish it); anything that contradicts the derivation is an ERROR. Never
# mutates anything.
#
# Output lines: BASE_SHA|FEATURE_SLUG|REPO|UNIT|EXISTS|CANDIDATE|DIRTY|OK
# Exit: 0 = safe to provision (DIRTY lines still require a human decision),
#       1 = collision or invalid state; message says exactly what and how to fix.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$#" -ge 1 ] || err "usage: preflight.sh <unit-slug>... (at least one unit)"

git rev-parse --git-dir >/dev/null 2>&1 || err "not inside a git repository"
herdr workspace list >/dev/null 2>&1 || err "herdr server unreachable; is a Herdr session running?"

base_sha="$(git rev-parse HEAD)"
printf 'BASE_SHA|%s\n' "$base_sha"
printf 'FEATURE_SLUG|%s\n' "$(feature_slug)"
printf 'REPO|%s|%s\n' "$(repo_name)" "$(repo_root)"

# Dirty tree: warn, never block. The skill asks the human go/no-go.
git status --porcelain | while IFS= read -r line; do
  [ -n "$line" ] && printf 'DIRTY|%s\n' "$line"
done

existing_labels="$(hj "print('\n'.join(w.get('label','') for w in j.get('workspaces', [])))" workspace list)"

# branch checked out at a registered git worktree path, if any
branch_worktree_path() { # $1 = branch
  git worktree list --porcelain | awk -v b="refs/heads/$1" '
    /^worktree /   { path = substr($0, 10) }
    /^branch / && $2 == b { print path }'
}

for unit in "$@"; do
  slugged="$(slugify "$unit")"
  [ "$slugged" = "$unit" ] || err "unit '$unit' is not a valid slug (want: '$slugged'). Pass pre-slugified unit names."
  branch="$(derive_branch "$unit")"
  path="$(derive_path "$unit")"

  if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
    at="$(branch_worktree_path "$branch")"
    if [ "$at" = "$path" ]; then
      printf 'EXISTS|%s|%s|%s\n' "$unit" "$branch" "$path"
      continue
    fi
    err "branch '$branch' already exists but is not checked out at the derived path '$path' (found: '${at:-nowhere}'). Leftover from a previous effort? Remove it (git branch -d '$branch') or run /teardown-worktrees, then rerun."
  fi
  [ -e "$path" ] && \
    err "directory '$path' already exists but branch '$branch' does not. Remove the directory (check contents first), then rerun."
  git worktree list --porcelain | grep -Fxq "worktree $path" && \
    err "git already has a worktree registered at '$path' on a different branch. Run 'git worktree list' to inspect."
  printf '%s\n' "$existing_labels" | grep -Fxq "$unit" && \
    err "a Herdr workspace labeled '$unit' already exists and is not this unit's worktree. Rename it or pick a different unit name."

  printf 'UNIT|%s|%s|%s\n' "$unit" "$branch" "$path"
done

# Copy candidates: untracked-and-gitignored files, heavy dirs excluded.
git ls-files --others --ignored --exclude-standard --directory 2>/dev/null | \
  grep -Ev '^(node_modules|dist|build|out|target|coverage|vendor|\.venv|venv|\.cache|\.direnv|\.next|\.turbo)(/|$)' | \
  grep -v '/$' | grep -v '\.DS_Store' | head -50 | while IFS= read -r f; do
    printf 'CANDIDATE|%s\n' "$f"
done

ok "preflight passed for $# unit(s) at base $base_sha"
