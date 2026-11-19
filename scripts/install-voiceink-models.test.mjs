import assert from "node:assert/strict"
import { createHash } from "node:crypto"
import { mkdtemp, mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { dirname, join } from "node:path"
import test from "node:test"

import { fileMatches, installModels, validateManifest } from "./install-voiceink-models.mjs"

function manifestFor(content, checksum = "sha256") {
  const bytes = Buffer.from(content)
  const hash = createHash(checksum === "sha256" ? "sha256" : "sha1")
  if (checksum === "gitBlobSha1") hash.update(`blob ${bytes.length}\0`)
  hash.update(bytes)
  return {
    version: 1,
    models: [{
      name: "Test model", repository: "example/model", revision: "a".repeat(40),
      folder: "model", files: [{ path: "Encoder.mlmodelc/weights/weight.bin", size: bytes.length,
        [checksum]: hash.digest("hex") }],
    }],
  }
}

async function fixture(t, content = "old model") {
  const root = await mkdtemp(join(tmpdir(), "voiceink-models-test-"))
  t.after(() => rm(root, { recursive: true, force: true }))
  const path = join(root, "model/Encoder.mlmodelc/weights/weight.bin")
  await mkdir(dirname(path), { recursive: true })
  await writeFile(path, content)
  return { root, path }
}

test("manifest rejects unsafe paths and unpinned revisions before installation", () => {
  const valid = manifestFor("model")
  assert.doesNotThrow(() => validateManifest(valid))
  for (const path of ["../outside", "/outside", "a/../../outside", "a\\outside"]) {
    const bad = structuredClone(valid)
    bad.models[0].files[0].path = path
    assert.throws(() => validateManifest(bad), /path/i)
  }
  valid.models[0].revision = "main"
  assert.throws(() => validateManifest(valid), /revision/i)
})

test("verified artifacts skip the network and preserve unrelated cache files", async (t) => {
  const { root, path } = await fixture(t, "good model")
  await writeFile(join(root, "model/custom-vocabulary.json"), "keep")
  const result = await installModels(manifestFor("good model"), root, {
    fetchImpl: () => { throw new Error("Network must not run") },
  })
  assert.equal(result.downloaded, 0)
  assert.equal(result.verified, 1)
  assert.equal(await readFile(path, "utf8"), "good model")
  assert.equal(await readFile(join(root, "model/custom-vocabulary.json"), "utf8"), "keep")
})

test("Git blob verification includes its size header", async (t) => {
  const { path } = await fixture(t, "model")
  const artifact = manifestFor("model", "gitBlobSha1").models[0].files[0]
  assert.equal(await fileMatches(path, artifact), true)
  artifact.gitBlobSha1 = createHash("sha1").update("model").digest("hex")
  assert.equal(await fileMatches(path, artifact), false)
})

test("verified download replaces an invalid file only after the response completes", async (t) => {
  const { root, path } = await fixture(t)
  const manifest = manifestFor("new model")
  const result = await installModels(manifest, root, {
    fetchImpl: async (url) => {
      assert.equal(await readFile(path, "utf8"), "old model")
      assert.equal(url, `https://huggingface.co/example/model/resolve/${"a".repeat(40)}/Encoder.mlmodelc/weights/weight.bin`)
      return new Response("new model")
    },
  })
  assert.equal(result.downloaded, 1)
  assert.equal(await readFile(path, "utf8"), "new model")
  assert.deepEqual(await readdir(dirname(path)), ["weight.bin"])
})

test("bad checksums and HTTP failures preserve the original file and clean temporary data", async (t) => {
  const { root, path } = await fixture(t)
  for (const response of [new Response("bad bytes"), new Response("unavailable", { status: 503 })]) {
    await assert.rejects(installModels(manifestFor("new model"), root, {
      fetchImpl: async () => response,
    }), /checksum|size|HTTP/i)
    assert.equal(await readFile(path, "utf8"), "old model")
    assert.deepEqual(await readdir(dirname(path)), ["weight.bin"])
  }
})

test("interrupted response bodies preserve existing artifacts and remove partial downloads", async (t) => {
  const { root, path } = await fixture(t)
  const body = new ReadableStream({
    start(controller) {
      controller.enqueue(Buffer.from("new"))
      controller.error(new Error("Connection interrupted"))
    },
  })
  await assert.rejects(installModels(manifestFor("new model"), root, {
    fetchImpl: async () => new Response(body),
  }), /interrupted/)
  assert.equal(await readFile(path, "utf8"), "old model")
  assert.deepEqual(await readdir(dirname(path)), ["weight.bin"])
})

test("downloads stay within the configured concurrency", async (t) => {
  const { root } = await fixture(t)
  const manifest = manifestFor("model")
  const artifact = manifest.models[0].files[0]
  manifest.models[0].files = [0, 1, 2, 3].map((index) => ({ ...artifact, path: `${index}.bin` }))
  let active = 0
  let peak = 0
  const result = await installModels(manifest, root, {
    concurrency: 2,
    fetchImpl: async () => {
      active++
      peak = Math.max(peak, active)
      await new Promise((done) => setTimeout(done, 10))
      active--
      return new Response("model")
    },
  })
  assert.equal(result.downloaded, 4)
  assert.equal(peak, 2)
})
