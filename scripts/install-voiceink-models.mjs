#!/usr/bin/env node

import { createHash } from "node:crypto"
import { createReadStream, createWriteStream } from "node:fs"
import { mkdir, mkdtemp, readFile, rename, rm, stat } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { Readable } from "node:stream"
import { pipeline } from "node:stream/promises"
import { fileURLToPath } from "node:url"

const relativePath = (value) => typeof value === "string" && value.length > 0
  && !value.includes("\\") && !value.includes("\0")
  && value.split("/").every((part) => part && part !== "." && part !== "..")

export function validateManifest(manifest) {
  if (manifest.version !== 1 || !Array.isArray(manifest.models) || !manifest.models.length) {
    throw new Error("Invalid VoiceInk model manifest")
  }
  const targets = new Set()
  for (const model of manifest.models) {
    if (!/^[\w.-]+\/[\w.-]+$/.test(model.repository)) throw new Error("Invalid model repository")
    if (!/^[a-f0-9]{40}$/.test(model.revision)) throw new Error("Model revision must be pinned")
    if (!relativePath(model.folder) || model.folder.includes("/")) throw new Error("Invalid model folder path")
    if (!Array.isArray(model.files) || !model.files.length) throw new Error("Model has no files")
    for (const file of model.files) {
      if (!relativePath(file.path)) throw new Error("Invalid model file path")
      if (!Number.isSafeInteger(file.size) || file.size < 0) throw new Error("Invalid model file size")
      const hashes = [file.sha256, file.gitBlobSha1].filter((hash) => hash !== undefined)
      if (hashes.length !== 1
          || (file.sha256 !== undefined && !/^[a-f0-9]{64}$/.test(file.sha256))
          || (file.gitBlobSha1 !== undefined && !/^[a-f0-9]{40}$/.test(file.gitBlobSha1))) {
        throw new Error("Model file needs one valid checksum")
      }
      const target = `${model.folder}/${file.path}`
      if (targets.has(target)) throw new Error(`Duplicate model file path: ${target}`)
      targets.add(target)
    }
  }
  return manifest
}

export async function fileMatches(path, file) {
  try {
    const info = await stat(path)
    if (!info.isFile() || info.size !== file.size) return false
    const hash = createHash(file.sha256 ? "sha256" : "sha1")
    if (file.gitBlobSha1) hash.update(`blob ${file.size}\0`)
    for await (const chunk of createReadStream(path)) hash.update(chunk)
    return hash.digest("hex") === (file.sha256 ?? file.gitBlobSha1)
  } catch (error) {
    if (error.code === "ENOENT" || error.code === "ENOTDIR") return false
    throw error
  }
}

async function installFile(model, file, root, fetchImpl, log) {
  const target = join(root, model.folder, file.path)
  if (await fileMatches(target, file)) return false
  await mkdir(dirname(target), { recursive: true })
  const temporary = await mkdtemp(join(dirname(target), ".voiceink-download-"))
  try {
    const url = `https://huggingface.co/${model.repository}/resolve/${model.revision}/${file.path.split("/").map(encodeURIComponent).join("/")}`
    if (file.size > 100_000_000) log(`VoiceInk: downloading ${model.folder}/${file.path} (${Math.round(file.size / 1_000_000)} MB)`)
    const response = await fetchImpl(url, { signal: AbortSignal.timeout(600_000) })
    if (!response.ok || !response.body) throw new Error(`HTTP ${response.status}: ${model.folder}/${file.path}`)
    const downloaded = join(temporary, "model")
    await pipeline(Readable.fromWeb(response.body), createWriteStream(downloaded, { flags: "wx" }))
    if (!await fileMatches(downloaded, file)) throw new Error(`Model checksum or size mismatch: ${model.folder}/${file.path}`)
    await rename(downloaded, target)
    return true
  } finally {
    await rm(temporary, { recursive: true, force: true })
  }
}

export async function installModels(manifest, root, { fetchImpl = fetch, concurrency = 3, log = () => {} } = {}) {
  validateManifest(manifest)
  if (!Number.isInteger(concurrency) || concurrency < 1 || concurrency > 8) throw new Error("Invalid download concurrency")
  const jobs = manifest.models.flatMap((model) => model.files.map((file) => ({ model, file })))
  const result = { verified: 0, downloaded: 0, bytes: 0 }
  let next = 0
  let failure
  const worker = async () => {
    while (!failure && next < jobs.length) {
      const { model, file } = jobs[next++]
      try {
        if (await installFile(model, file, root, fetchImpl, log)) result.downloaded++
        result.verified++
        result.bytes += file.size
      } catch (error) {
        failure ??= error
      }
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, jobs.length) }, worker))
  if (failure) throw failure
  return result
}

async function main() {
  if (process.platform !== "darwin") return
  const manifest = JSON.parse(await readFile(new URL("../.config/voiceink/models.json", import.meta.url), "utf8"))
  const root = join(homedir(), "Library/Application Support/FluidAudio/Models")
  console.log("VoiceInk: verifying pinned local transcription models.")
  const result = await installModels(manifest, root, { log: console.log })
  console.log(`VoiceInk: verified ${result.verified} artifacts (${result.bytes.toLocaleString("en-US")} bytes); downloaded ${result.downloaded}.`)
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message)
    process.exitCode = 1
  })
}
