import type { Plugin } from "@opencode-ai/plugin"

export const ProjectMemoryPlugin: Plugin = async ({ $, worktree }) => {
  const home = process.env.HOME
  if (!home) return {}

  const script = `${home}/.dotfiles/scripts/project-memory.sh`
  const result = await $`${script} --path ${worktree}`.quiet().nothrow()
  const memoryPath = String(result.stdout).trim()

  if (result.exitCode !== 0) {
    console.warn(`[project-memory] ${String(result.stderr).trim() || "helper failed"}`)
    return {}
  }
  if (!memoryPath) return {}

  return {
    config: async (config) => {
      if (!config.instructions?.includes(memoryPath)) {
        config.instructions = [...(config.instructions ?? []), memoryPath]
      }
    },
  }
}
