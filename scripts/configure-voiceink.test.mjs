import assert from "node:assert/strict"
import { test } from "node:test"
import { readFileSync } from "node:fs"
import { buildPreferences } from "./configure-voiceink.mjs"

const config = JSON.parse(readFileSync(new URL("../.config/voiceink/settings.json", import.meta.url)))

test("external microphone priority survives disconnection and USB port changes", () => {
  const live = [
    { name: "MacBook Pro Microphone", id: "builtin", modelUID: "Digital Mic" },
    { name: "Shure MV7", id: "shure-new-port", modelUID: "stable-shure-model" },
    { name: "Sennheiser Profile", id: "sennheiser", modelUID: "stable-sennheiser" },
  ]
  const microphoneIds = { "Shure MV7": ["shure-previous-port"] }
  const result = buildPreferences(config, live, [], [], microphoneIds)
  const mics = result.data.prioritizedDevices
  assert.equal(mics[0].id, "sennheiser")
  assert.ok(mics.findIndex((m) => m.id === "shure-new-port") > 0)
  assert.ok(mics.findIndex((m) => m.id === "shure-new-port") < mics.findIndex((m) => m.id === "builtin"))
  assert.ok(mics.some((m) => m.id === "shure-previous-port"))
  const next = buildPreferences(config, [], [], mics)
  assert.ok(next.data.prioritizedDevices.some((m) => m.modelUID === "stable-shure-model"))
})

test("applying the local mode preserves unrelated modes and settings", () => {
  const other = { id: "other-mode", name: "Existing mode", isDefault: true }
  const existing = { ...config.mode, selectedPromptId: "user-prompt", icon: { kind: "symbol", value: "receipt.fill" } }
  const result = buildPreferences(config, [], [other, existing])
  assert.equal(result.data.modeConfigurationsV2.length, 2)
  assert.equal(result.data.modeConfigurationsV2[0].name, "Existing mode")
  assert.equal(result.data.modeConfigurationsV2[0].isDefault, false)
  assert.equal(result.values.activeConfigurationId, config.mode.id)
  assert.equal(result.values.primaryRecordingShortcutMode, "toggle")
  assert.deepEqual(result.data.Shortcut_primaryRecording, {
    kind: "key", keyCode: 49, modifierFlagsRawValue: 524288,
  })
  assert.equal(result.values.secondaryRecordingShortcut, "none")
  assert.equal(result.data.modeConfigurationsV2[1].selectedLanguage, "auto")
  assert.equal(result.data.modeConfigurationsV2[1].isAIEnhancementEnabled, true)
  assert.equal(result.data.modeConfigurationsV2[1].selectedPromptId, "user-prompt")
  assert.deepEqual(result.data.modeConfigurationsV2[1].icon, existing.icon)
})
