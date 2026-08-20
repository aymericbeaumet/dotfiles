import type { Plugin } from "@opencode-ai/plugin"

export const TmuxPanePlugin: Plugin = async ({ $ }) => {
  const pane = process.env.TMUX_PANE
  if (!pane) return {}

  const started = await $`tmux set-option -p -t ${pane} @agent-kind opencode`
    .quiet()
    .nothrow()
  if (started.exitCode !== 0) return {}

  // Replace a title inherited from the previous foreground application.
  await $`tmux set-option -p -t ${pane} pane-title OpenCode`.quiet().nothrow()

  return {
    dispose: async () => {
      const current = await $`tmux show-options -p -v -t ${pane} @agent-kind`
        .quiet()
        .nothrow()
      if (String(current.stdout).trim() !== "opencode") return

      await $`tmux set-option -p -t ${pane} pane-title ""`.quiet().nothrow()
      await $`tmux set-option -p -u -t ${pane} @agent-kind`.quiet().nothrow()
    },
  }
}
