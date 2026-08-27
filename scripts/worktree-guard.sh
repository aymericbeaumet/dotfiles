#!/usr/bin/env bash

# PreToolUse guard: bonsai is the only worktree manager.
#
# Reads the hook payload on stdin and blocks (exit 2) harness-native worktree
# tools and direct `git worktree` invocations, pointing the agent at bonsai.
# The stderr message is fed back to the model so it can self-correct.

set -euo pipefail

export LC_ALL=C

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat 2>/dev/null || true)
[[ -n "$payload" ]] || exit 0

tool_name=$(jq -r '.tool_name // empty' <<<"$payload" 2>/dev/null || true)

case "$tool_name" in
  EnterWorktree | ExitWorktree)
    printf '%s\n' \
      'Harness-native worktrees are disabled. Manage worktrees with bonsai instead: bonsai add <branch> prints the worktree path. See the bonsai skill.' >&2
    exit 2
    ;;
esac

# Shell command may be a string (Claude) or an argv array (Codex).
command_text=$(jq -r \
  '.tool_input.command // empty | if type == "array" then join(" ") else . end' \
  <<<"$payload" 2>/dev/null || true)
[[ -n "$command_text" ]] || exit 0

# Match `worktree` as a git subcommand within one pipeline segment.
if jq -en --arg c "$command_text" \
  '$c | test("\\bgit\\b[^\\n;|&]*\\sworktree(\\s|$)")' >/dev/null 2>&1; then
  printf '%s\n' \
    'Direct git worktree usage is disabled. Manage worktrees with bonsai instead: bonsai add/list/remove/clean (see the bonsai skill or run: bonsai agents).' >&2
  exit 2
fi

exit 0
