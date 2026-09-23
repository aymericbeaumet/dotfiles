---
name: push
description: Synchronize and push existing commits without staging or committing. Use when the user asks to push or publish the current branch.
---

# Push

Do not stage files or create, amend, squash, or otherwise rewrite commits except for the explicit
upstream rebase below. Preserve all staged and unstaged worktree changes.

1. Inspect the current branch, worktree and index status, configured upstream, recent commits, and
   remotes before changing directories. Record the source branch, HEAD, synchronization upstream,
   and Git's resolved push remote and destination ref. Use `@{push}` where resolvable and honor
   `branch.<name>.pushRemote`, `remote.pushDefault`, `remote.<name>.push`, and `push.default`.
   The synchronization upstream can differ from the push destination. Fall back to `origin` and
   the source branch name only for an unconfigured first publication. Stop when configuration
   forbids a default push, leaves the target ambiguous, or would publish additional refs.
2. Require a bonsai worktree using the bonsai skill's existing-work handoff, unless the repository's
   `AGENTS.md` designates direct work on its default branch; then stay in the current checkout and
   skip the handoff. Preserve the recorded
   source HEAD and destination; leave pending source changes untouched. A new task branch must use
   `--base <source-head>` and must not become a different remote branch merely because of the move.
3. Fetch the recorded remotes. Compare the intended commits with the synchronization upstream,
   when one exists, and separately with the push destination. When the synchronization upstream
   is ahead or histories diverged, require clean source and destination worktrees and indexes,
   then rebase onto that upstream. Recheck the captured source HEAD before synchronization; stop
   on concurrent changes. Keep the original source branch consistent with any synchronized HEAD
   without overwriting pending work. Stop if the resulting push would not be a fast-forward;
   never change its destination to avoid a rejection.
4. If rebase conflicts occur, resolve clear conflicts, stage only the resolutions, and continue the
   rebase. If a resolution is ambiguous or risky, abort the rebase and stop the pipeline.
5. Push the synchronized HEAD to the recorded remote and full destination ref explicitly. If no
   upstream existed, configure it for the intended source branch after a successful push. Never
   infer the destination from a temporary task branch's name or upstream.
6. Never force-push or bypass hooks.

Report the branch, synchronization performed, and push result.
