import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent"

const MAX_TITLE_LENGTH = 64

function promptTitle(prompt: string) {
  const title = prompt
    .replace(/\s+/g, " ")
    .replace(/^[#>*`\-\s]+/, "")
    .trim()

  if (title.length <= MAX_TITLE_LENGTH) return title
  return `${title.slice(0, MAX_TITLE_LENGTH - 1).trimEnd()}...`
}

function setTerminalTitle(pi: ExtensionAPI, ctx: ExtensionContext, fallback?: string) {
  if (!ctx.hasUI) return
  const title = pi.getSessionName() || fallback || "New Session"
  ctx.ui.setTitle(`PI | ${title}`)
}

export default function tmuxTitle(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    setTerminalTitle(pi, ctx)
  })

  pi.on("session_info_changed", (event, ctx) => {
    setTerminalTitle(pi, ctx, event.name)
  })

  pi.on("before_agent_start", (event, ctx) => {
    if (!pi.getSessionName()) {
      const title = promptTitle(event.prompt)
      if (title) pi.setSessionName(title)
    }
    setTerminalTitle(pi, ctx)
  })
}
