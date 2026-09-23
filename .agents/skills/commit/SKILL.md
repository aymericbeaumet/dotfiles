---
name: commit
description: Stage all changes and create a Conventional Commit without pushing. Use when the user asks to commit all current changes.
---

## Task

1. **Capture the source work**: Inspect the current branch, HEAD, upstream, index, complete tracked
   diff, and untracked files before changing directories. The request refers to this checkout's
   changes, including its existing local commits.
2. **Require a bonsai worktree** unless the repository's `AGENTS.md` designates direct work on its
   default branch, in which case stay in the current checkout and skip this step. Otherwise
   follow the bonsai skill's existing-work handoff. When creating a
   task branch, base it on the captured source HEAD and copy the intended pending changes without
   altering their originals. Verify the destination contains the complete intended changes and no
   unrelated additions before staging. Continue there without waiting for confirmation.

3. **Stage all changes**: Run `git add -A` to stage everything (tracked and untracked).

4. **Generate a commit message**: Analyze the staged diff (`git diff --cached`) and recent commit history. The message MUST follow the latest published [Conventional Commits specification](https://www.conventionalcommits.org/): `<type>[optional scope][optional !]: <description>`, followed by an optional body and optional footers separated by blank lines. Use `feat` for a feature and `fix` for a bug fix. Mark a breaking change with `!` before `:` or a `BREAKING CHANGE:` footer. Other types such as `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, and `test` are allowed when they accurately describe the change. Keep the first line under 72 characters. Add a body only if the change is non-trivial. If the user's request includes commit-message guidance, use it as guidance, but still write and validate the message yourself.

5. **Commit**: Create the commit. Do NOT amend an existing commit. Do NOT use `--no-verify`. Do NOT push.

Report the commit message, number of files changed, and worktree path. If work was copied from
another checkout, state that its original pending changes remain there.
