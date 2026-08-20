#!/usr/bin/env node

import { spawn } from "node:child_process"
import { realpathSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join, resolve } from "node:path"
import { createInterface } from "node:readline"

const cwd = resolve(process.argv[2] ?? process.cwd())
const codexHome = resolve(process.env.CODEX_HOME ?? join(homedir(), ".codex"))
const hooksPath = join(codexHome, "hooks.json")
const configPath = join(codexHome, "config.toml")

function canonicalPath(path) {
  try {
    return realpathSync(path)
  } catch {
    return resolve(path)
  }
}

function normalizedEventName(name) {
  return String(name).replace(/[^a-z0-9]/gi, "").toLowerCase()
}

class AppServer {
  constructor() {
    this.nextID = 1
    this.pending = new Map()
    this.stderr = ""
    this.child = spawn("codex", ["app-server", "--listen", "stdio://"], {
      cwd,
      env: process.env,
      stdio: ["pipe", "pipe", "pipe"],
    })

    this.child.stderr.on("data", (chunk) => {
      this.stderr = `${this.stderr}${chunk}`.slice(-16_384)
    })
    this.child.once("error", (error) => this.rejectAll(error))
    this.child.once("exit", (code, signal) => {
      if (this.pending.size > 0) {
        const detail = this.stderr.trim()
        this.rejectAll(
          new Error(
            `codex app-server exited (${signal ?? code ?? "unknown"})${detail ? `: ${detail}` : ""}`,
          ),
        )
      }
    })

    this.lines = createInterface({ input: this.child.stdout })
    this.lines.on("line", (line) => this.handleLine(line))
  }

  handleLine(line) {
    let message
    try {
      message = JSON.parse(line)
    } catch {
      return
    }

    if (message.method && Object.hasOwn(message, "id")) {
      this.send({
        jsonrpc: "2.0",
        id: message.id,
        error: { code: -32601, message: `Unsupported server request: ${message.method}` },
      })
      return
    }

    if (!Object.hasOwn(message, "id")) return
    const pending = this.pending.get(message.id)
    if (!pending) return
    this.pending.delete(message.id)
    clearTimeout(pending.timeout)
    if (message.error) {
      pending.reject(new Error(`${pending.method}: ${JSON.stringify(message.error)}`))
    } else {
      pending.resolve(message.result)
    }
  }

  rejectAll(error) {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeout)
      pending.reject(error)
    }
    this.pending.clear()
  }

  send(message) {
    this.child.stdin.write(`${JSON.stringify(message)}\n`)
  }

  request(method, params) {
    const id = this.nextID++
    return new Promise((resolveRequest, rejectRequest) => {
      const timeout = setTimeout(() => {
        this.pending.delete(id)
        rejectRequest(new Error(`${method}: timed out`))
      }, 15_000)
      this.pending.set(id, {
        method,
        resolve: resolveRequest,
        reject: rejectRequest,
        timeout,
      })
      this.send({ jsonrpc: "2.0", id, method, params })
    })
  }

  notify(method) {
    this.send({ jsonrpc: "2.0", method })
  }

  stop() {
    this.lines.close()
    this.child.stdin.end()
    this.child.kill()
  }
}

function hooksEntry(response) {
  const canonicalCwd = canonicalPath(cwd)
  return response.data.find((entry) => canonicalPath(entry.cwd) === canonicalCwd) ?? response.data[0]
}

function assertNoHookErrors(entry) {
  if (!entry) throw new Error(`hooks/list returned no entry for ${cwd}`)
  if (entry.errors.length > 0) {
    throw new Error(entry.errors.map((error) => `${error.path}: ${error.message}`).join("\n"))
  }
}

const hooksFile = JSON.parse(readFileSync(hooksPath, "utf8"))
const eventNames = Object.keys(hooksFile.hooks ?? {})
if (eventNames.length === 0) throw new Error(`${hooksPath} contains no hooks`)

const canonicalHooksPath = canonicalPath(hooksPath)
const canonicalConfigPath = canonicalPath(configPath)
const server = new AppServer()

try {
  await server.request("initialize", {
    clientInfo: {
      name: "dotfiles_hook_configurator",
      title: "Dotfiles Codex Hook Configurator",
      version: "1.0.0",
    },
  })
  server.notify("initialized")

  const initialEntry = hooksEntry(await server.request("hooks/list", { cwds: [cwd] }))
  assertNoHookErrors(initialEntry)

  const trackedHooks = initialEntry.hooks.filter(
    (hook) => canonicalPath(hook.sourcePath) === canonicalHooksPath,
  )
  if (trackedHooks.length === 0) {
    throw new Error(`Codex did not discover tracked hooks from ${hooksPath}`)
  }

  const inlineHooks = initialEntry.hooks.filter(
    (hook) => canonicalPath(hook.sourcePath) === canonicalConfigPath,
  )
  const edits = []
  const deletedEvents = new Set()

  for (const eventName of eventNames) {
    const normalizedEvent = normalizedEventName(eventName)
    const inlineForEvent = inlineHooks.filter(
      (hook) => normalizedEventName(hook.eventName) === normalizedEvent,
    )
    if (inlineForEvent.length === 0) continue

    const trackedHashes = new Map()
    for (const hook of trackedHooks) {
      if (normalizedEventName(hook.eventName) !== normalizedEvent) continue
      trackedHashes.set(hook.currentHash, (trackedHashes.get(hook.currentHash) ?? 0) + 1)
    }

    const mirrored = inlineForEvent.every((hook) => {
      const remaining = trackedHashes.get(hook.currentHash) ?? 0
      if (remaining === 0) return false
      trackedHashes.set(hook.currentHash, remaining - 1)
      return true
    })

    if (mirrored) {
      deletedEvents.add(normalizedEvent)
      edits.push({
        keyPath: `hooks.${eventName}`,
        value: null,
        mergeStrategy: "replace",
      })
    } else {
      console.warn(`[codex-hooks] preserving non-mirrored inline ${eventName} hooks`)
    }
  }

  const trustState = Object.fromEntries(
    trackedHooks.map((hook) => [
      hook.key,
      { enabled: true, trusted_hash: hook.currentHash },
    ]),
  )
  edits.push({ keyPath: "hooks.state", value: trustState, mergeStrategy: "upsert" })

  await server.request("config/batchWrite", {
    edits,
    reloadUserConfig: true,
  })

  const finalEntry = hooksEntry(await server.request("hooks/list", { cwds: [cwd] }))
  assertNoHookErrors(finalEntry)
  const finalTrackedHooks = finalEntry.hooks.filter(
    (hook) => canonicalPath(hook.sourcePath) === canonicalHooksPath,
  )
  if (finalTrackedHooks.length !== trackedHooks.length) {
    throw new Error("tracked Codex hook count changed during configuration")
  }
  for (const hook of finalTrackedHooks) {
    if (!hook.enabled || String(hook.trustStatus).toLowerCase() !== "trusted") {
      throw new Error(`Codex hook is not enabled and trusted: ${hook.key}`)
    }
  }

  const remainingMirrors = finalEntry.hooks.filter(
    (hook) =>
      canonicalPath(hook.sourcePath) === canonicalConfigPath &&
      deletedEvents.has(normalizedEventName(hook.eventName)),
  )
  if (remainingMirrors.length > 0) {
    throw new Error("mirrored inline Codex hooks remain after migration")
  }

  console.log(`Configured and trusted ${finalTrackedHooks.length} Codex hooks from ${hooksPath}`)
} finally {
  server.stop()
}
