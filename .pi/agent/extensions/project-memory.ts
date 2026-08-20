import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

export default function projectMemory(pi: ExtensionAPI) {
  const home = process.env.HOME
  if (!home) return

  const script = `${home}/.dotfiles/scripts/project-memory.sh`
  pi.on("before_agent_start", async (event, ctx) => {
    const result = await pi
      .exec(script, [ctx.cwd], {
        cwd: ctx.cwd,
        signal: ctx.signal,
        timeout: 5000,
      })
      .catch((error: unknown) => {
        console.warn(`[project-memory] ${String(error)}`)
        return undefined
      })

    if (!result) return
    if (result.code !== 0) {
      console.warn(`[project-memory] ${result.stderr.trim() || "helper failed"}`)
      return
    }

    const memory = result.stdout.trim()
    if (!memory) return
    return { systemPrompt: `${event.systemPrompt}\n\n${memory}` }
  })
}
