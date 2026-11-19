#!/usr/bin/env node

import { execFileSync } from "node:child_process"
import { readFileSync } from "node:fs"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"

const baseURL = "http://127.0.0.1:11434"

export function parseModels(text) {
  const models = text.split("\n").map((line) => line.split("#", 1)[0].trim()).filter(Boolean)
  for (const model of models) {
    if (!/^[\w][\w./-]*:[\w][\w.-]*$/.test(model)) {
      throw new Error(`Use an explicit model tag such as ministral-3:8b: ${model}`)
    }
  }
  return [...new Set(models)]
}

export async function configureOllama(models, {
  startService = () => execFileSync("brew", ["services", "start", "ollama"], { stdio: "inherit" }),
  fetchImpl = fetch,
  sleep = (ms) => new Promise((done) => setTimeout(done, ms)),
  attempts = 30,
  log = () => {},
} = {}) {
  startService()
  let tags
  for (let attempt = 0; attempt < attempts; attempt++) {
    try {
      const response = await fetchImpl(`${baseURL}/api/tags`, { signal: AbortSignal.timeout(2000) })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const body = await response.json()
      if (!Array.isArray(body.models)) throw new Error("Invalid model list")
      tags = body.models
      break
    } catch {
      if (attempt < attempts - 1) await sleep(1000)
    }
  }
  if (!tags) throw new Error(`Ollama did not become ready at ${baseURL}; check brew services info ollama.`)

  const available = new Set(tags.map((model) => model.name))
  const result = { installed: [], present: [] }
  for (const model of models) {
    if (available.has(model)) {
      result.present.push(model)
      log(`Ollama: ${model} is already installed.`)
      continue
    }
    log(`Ollama: downloading ${model}.`)
    const response = await fetchImpl(`${baseURL}/api/pull`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ model, stream: false }),
      signal: AbortSignal.timeout(3_600_000),
    })
    const body = await response.json()
    if (!response.ok || body.error || body.status !== "success") {
      throw new Error(`Ollama pull ${model} failed: ${body.error ?? body.status ?? response.status}`)
    }
    result.installed.push(model)
    log(`Ollama: ${model} installed.`)
  }
  return result
}

async function main() {
  if (process.platform !== "darwin") return
  const models = parseModels(readFileSync(new URL("../.config/ollama/models.txt", import.meta.url), "utf8"))
  await configureOllama(models, { log: console.log })
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message)
    process.exitCode = 1
  })
}
