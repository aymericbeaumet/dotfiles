import assert from "node:assert/strict"
import { test } from "node:test"
import { configureOllama, parseModels } from "./configure-ollama.mjs"

test("model list accepts explicit tags and comments without duplicate pulls", () => {
  assert.deepEqual(parseModels("# local models\nministral-3:8b\n\nministral-3:8b # duplicate\n"), ["ministral-3:8b"])
  assert.throws(() => parseModels("ministral-3"), /explicit model tag/)
  assert.throws(() => parseModels("ministral-3:8b;anything"), /explicit model tag/)
})

test("waits for service readiness and installs only missing models", async () => {
  const calls = []
  let checks = 0
  const result = await configureOllama(["existing:8b", "ministral-3:8b"], {
    startService: () => calls.push("start"),
    sleep: async () => {},
    fetchImpl: async (url, options) => {
      if (url.endsWith("/api/tags")) {
        if (checks++ === 0) throw new Error("starting")
        return Response.json({ models: [{ name: "existing:8b" }] })
      }
      calls.push(JSON.parse(options.body))
      return Response.json({ status: "success" })
    },
  })
  assert.equal(checks, 2)
  assert.deepEqual(calls, ["start", { model: "ministral-3:8b", stream: false }])
  assert.deepEqual(result, { installed: ["ministral-3:8b"], present: ["existing:8b"] })
})

test("an unavailable service fails without attempting any model pull", async () => {
  let calls = 0
  await assert.rejects(configureOllama(["ministral-3:8b"], {
    startService: () => {}, sleep: async () => {}, attempts: 2,
    fetchImpl: async () => { calls++; throw new Error("offline") },
  }), /did not become ready/)
  assert.equal(calls, 2)
})

test("download errors fail setup without reporting the model installed", async () => {
  await assert.rejects(configureOllama(["ministral-3:8b"], {
    startService: () => {},
    fetchImpl: async (url) => url.endsWith("/api/tags")
      ? Response.json({ models: [] })
      : Response.json({ error: "disk full" }),
  }), /disk full/)
})
