---
name: teardown-worktrees
description: Safely remove worktrees created by setup-worktrees - merged-and-clean ones in a confirmed batch, anything holding work only with per-unit consent.
disable-model-invocation: true
---

Clean up worktrees created by `/setup-worktrees`, reading everything from live git and Herdr state. Scripts and the Herdr reference live in the sibling skill: `../setup-worktrees/scripts/` and `../setup-worktrees/HERDR.md`.

Scope: worktrees on `wt/<current-feature-slug>/*` branches, invoked from the effort's feature branch. With the argument `all`, sweep every `wt/*` worktree in the repo instead.

## Steps

### 1. Classify

Run `../setup-worktrees/scripts/teardown.sh classify [all]`. Each `WORKTREE|branch|path|merged|clean|workspace` line lands in one of two buckets:

- **merged + clean**: removable with zero information loss; the commits live on through the merge.
- **anything else** (unmerged commits, dirty tree, or both): holds work that removal would orphan.

If an agent is still `working` in a unit's workspace, treat that unit as holding work regardless of git state.

### 2. Confirm

Present both buckets as a table with each unit's exact state. Proposal: remove the merged-and-clean batch (worktree removed, branch deleted); leave the rest untouched. The user may additionally consent, per unit and explicitly, to removing a work-holding worktree; its checkout is removed but its branch is always kept (deleting an unmerged branch is the one destructive act this skill never performs; point the user at `git branch -D` if they truly want it). Done when the user has confirmed the removal list.

### 3. Remove

Per confirmed unit:

```sh
../setup-worktrees/scripts/teardown.sh remove <path> <branch> delete-branch   # merged + clean
../setup-worktrees/scripts/teardown.sh remove <path> <branch> keep-branch    # user-consented, holds work
```

The script closes the Herdr workspace, removes the checkout, prunes, and (delete-branch mode only, with merged-ness re-proven) deletes the branch. Done when every confirmed unit reports `OK: removed`.

### 4. Report

Check `herdr workspace list` for a stray workspace Herdr may have opened for the source checkout during removal and close it. Then present the final table: every classified unit and its outcome (removed + branch deleted / removed + branch kept / left in place and why). Done when nothing in the chosen scope is unaccounted for.
