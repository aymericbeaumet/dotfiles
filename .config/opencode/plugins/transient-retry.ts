import type { Plugin } from "@opencode-ai/plugin"

const retryDelaysMs = [15_000, 60_000, 300_000] as const
const transientPattern =
  /stream_read_error|server_is_overloaded|service[_ -]?unavailable|server capacity|overloaded|internal[_ -]?server[_ -]?error|(?:connection|socket).*(?:closed|lost|reset|hang up)|econnreset|etimedout|timed? out|timeout|fetch failed|network error|upstream error|rate[_ -]?limit|too many requests|\b(?:429|500|502|503|504|524|529)\b/i
const permanentPattern =
  /authentication|unauthori[sz]ed|forbidden|oauth|billing|credit balance|usage limit|weekly limit|monthly limit|quota|invalid request|context window|policy|permission|model.*not.*found/i

function errorText(error: unknown): string {
  if (!error || typeof error !== "object") return ""

  const value = error as Record<string, unknown>
  const data =
    value.data && typeof value.data === "object"
      ? (value.data as Record<string, unknown>)
      : {}

  return [value.name, data.message, data.statusCode, data.responseBody]
    .filter((part) => part !== undefined && part !== null)
    .join(" ")
}

export function isTransientSessionError(error: unknown): boolean {
  const text = errorText(error)
  return text.length > 0 && !permanentPattern.test(text) && transientPattern.test(text)
}

export const TransientRetryPlugin: Plugin = async ({ client }) => {
  const attempts = new Map<string, number>()
  const pending = new Map<string, ReturnType<typeof setTimeout>>()
  const statuses = new Map<string, string>()

  const log = async (level: "warn" | "error", message: string) => {
    await client.app
      .log({
        body: {
          service: "transient-retry",
          level,
          message,
        },
      })
      .catch(() => undefined)
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.status") {
        const sessionID = event.properties.sessionID
        const status = event.properties.status.type
        statuses.set(sessionID, status)
        if (status === "busy" || status === "retry") {
          const timer = pending.get(sessionID)
          if (timer) clearTimeout(timer)
          pending.delete(sessionID)
        }
        return
      }

      if (event.type === "session.idle") {
        statuses.set(event.properties.sessionID, "idle")
        return
      }

      if (event.type === "session.deleted") {
        const sessionID = event.properties.info.id
        const timer = pending.get(sessionID)
        if (timer) clearTimeout(timer)
        pending.delete(sessionID)
        attempts.delete(sessionID)
        statuses.delete(sessionID)
        return
      }

      if (event.type === "message.updated" && event.properties.info.role === "user") {
        const sessionID = event.properties.info.sessionID
        const timer = pending.get(sessionID)
        if (timer) clearTimeout(timer)
        pending.delete(sessionID)
        return
      }

      if (event.type !== "session.error") return

      const sessionID = event.properties.sessionID
      if (!sessionID || !isTransientSessionError(event.properties.error)) return
      if (pending.has(sessionID)) return

      const attempt = attempts.get(sessionID) ?? 0
      if (attempt >= retryDelaysMs.length) return

      const delay = retryDelaysMs[attempt]
      attempts.set(sessionID, attempt + 1)
      await log(
        "warn",
        `Scheduling guarded continuation ${attempt + 1}/${retryDelaysMs.length} in ${delay / 1000}s for ${sessionID}`,
      )

      const timer = setTimeout(() => {
        pending.delete(sessionID)
        const status = statuses.get(sessionID)
        if (status === "busy" || status === "retry") return

        void client.session
          .prompt({
            path: { id: sessionID },
            body: {
              parts: [
                {
                  type: "text",
                  text: "Continue from the last verified state after the transient provider failure. Inspect the current session state first, preserve completed work, and do not repeat completed side effects.",
                },
              ],
            },
          })
          .catch((error: unknown) =>
            log("error", `Guarded continuation failed for ${sessionID}: ${String(error)}`),
          )
      }, delay)

      pending.set(sessionID, timer)
    },
  }
}
