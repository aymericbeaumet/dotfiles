import type { Plugin } from "@opencode-ai/plugin"

// Worktree guard — bonsai is the only worktree manager.
//
// Blocks direct `git worktree` invocations from the shell tool; the thrown
// message is surfaced to the model so it self-corrects to bonsai. Mirrors
// scripts/worktree-guard.sh, which covers Claude Code and Codex.

const GIT_WORKTREE = /\bgit\b[^\n;|&]*\sworktree(\s|$)/

export const WorktreeGuardPlugin: Plugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return
      const args = output?.args
      if (!args || typeof args !== "object") return

      const command = (args as Record<string, unknown>).command
      if (typeof command !== "string" || !GIT_WORKTREE.test(command)) return

      throw new Error(
        "Direct git worktree usage is disabled. Manage worktrees with bonsai instead: bonsai add/list/remove/clean (see the bonsai skill or `bonsai agents`).",
      )
    },
  }
}
