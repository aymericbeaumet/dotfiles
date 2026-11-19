#!/usr/bin/env node

import { execFileSync, spawnSync } from "node:child_process"
import { existsSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const domain = "com.prakashjoshipax.VoiceInk"
const scriptDir = dirname(fileURLToPath(import.meta.url))

export function buildPreferences(config, available, modes = [], remembered = [], microphoneIds = {}) {
  const devices = config.microphones.flatMap((microphone) => {
    const live = available.filter((device) => device.name === microphone.name)
    const saved = remembered.filter((device) => device.name === microphone.name)
    const ids = microphoneIds[microphone.name] ?? microphone.ids ?? []
    const configured = ids.map((id) => ({
      id,
      name: microphone.name,
      ...(microphone.modelUID ? { modelUID: microphone.modelUID } : {}),
    }))
    return [...live, ...saved, ...configured]
  })
  const unique = devices.filter((device, index) =>
    devices.findIndex((candidate) => candidate.id === device.id) === index)
    .map(({ id, name, modelUID }, priority) => ({
      id, name, priority, ...(modelUID ? { modelUID } : {}),
    }))
  return {
    values: { ...config.preferences, activeConfigurationId: config.mode.id },
    data: {
      Shortcut_primaryRecording: config.shortcut,
      prioritizedDevices: unique,
      modeConfigurationsV2: [
        ...modes.filter((mode) => mode.id !== config.mode.id)
          .map((mode) => ({ ...mode, isDefault: false })),
        { ...modes.find((mode) => mode.id === config.mode.id), ...config.mode },
      ],
    },
  }
}

function existingJSONData(plist, key) {
  const result = spawnSync("/usr/bin/plutil", ["-extract", key, "raw", "-o", "-", "-"], {
    input: plist, encoding: "utf8",
  })
  if (result.status !== 0) return []
  return JSON.parse(Buffer.from(result.stdout.trim(), "base64").toString("utf8"))
}

async function main() {
  if (process.platform !== "darwin") return
  const configDir = join(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "voiceink")
  const config = JSON.parse(readFileSync(join(configDir, "settings.json"), "utf8"))
  const microphoneIdsPath = join(configDir, "microphones.local.json")
  const microphoneIds = existsSync(microphoneIdsPath)
    ? JSON.parse(readFileSync(microphoneIdsPath, "utf8"))
    : {}
  const wasRunning = spawnSync("/usr/bin/pgrep", ["-x", "VoiceInk"]).status === 0
  if (wasRunning) {
    execFileSync("/usr/bin/osascript", ["-e", 'tell application "VoiceInk" to quit'])
    for (let attempt = 0; attempt < 30; attempt++) {
      if (spawnSync("/usr/bin/pgrep", ["-x", "VoiceInk"]).status !== 0) break
      if (attempt === 29) throw new Error("VoiceInk is still running; finish recording and retry.")
      await new Promise((done) => setTimeout(done, 100))
    }
  }
  try {
    const exported = spawnSync("/usr/bin/defaults", ["export", domain, "-"], { encoding: "utf8" })
    const plist = exported.status === 0 ? exported.stdout : null
    const available = JSON.parse(execFileSync("/usr/bin/swift", [join(scriptDir, "voiceink-audio-devices.swift")], {
      encoding: "utf8", timeout: 60_000,
    }))
    const prefs = buildPreferences(config, available,
      plist ? existingJSONData(plist, "modeConfigurationsV2") : [],
      plist ? existingJSONData(plist, "prioritizedDevices") : [], microphoneIds)
    for (const [key, value] of Object.entries(prefs.values)) {
      const type = typeof value === "boolean" ? "-bool" : "-string"
      execFileSync("/usr/bin/defaults", ["write", domain, key, type, String(value)])
    }
    for (const [key, value] of Object.entries(prefs.data)) {
      const data = Buffer.from(JSON.stringify(value)).toString("hex")
      execFileSync("/usr/bin/defaults", ["write", domain, key, "-data", data])
    }
    console.log("VoiceInk: local Parakeet Ultra, automatic English/French; Alt+Space starts/stops recording.")
    console.log(`Microphone order: ${config.microphones.map((mic) => mic.name).join(" → ")}`)
    console.log(`Connected inputs: ${available.map((mic) => mic.name).join(", ")}`)
  } finally {
    if (wasRunning) execFileSync(join(scriptDir, "open-url.sh"), ["/Applications/VoiceInk.app"])
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message)
    process.exitCode = 1
  })
}
