# Shared agent defaults

These defaults apply across repositories and clients. A repository's own `AGENTS.md` adds the
project-specific commands and constraints.

## Token-efficient shell use

- Prefix every shell command with `rtk`.
- Prefer RTK's native wrappers for Git, GitHub, tests, builds, package managers, file reads, and
  searches. Use `rtk proxy <command>` only when exact unfiltered output is required.
- If RTK reports a saved full-output path after a failure, inspect that file instead of rerunning
  the noisy command.

## Code discovery

- Start unfamiliar behavior, architecture, or symbol discovery with Semble's `search` tool.
- Use `find_related` from a promising result when the relationship is semantic rather than a
  literal reference.
- Open the returned file at the returned lines; do not immediately repeat the same discovery with
  grep or broad file reads.
- For prose or configuration discovery, use
  `rtk proxy semble search --content docs config --max-snippet-lines 10 "<query>" <path>`.
- Use `rg` for exact strings, filenames, and exhaustive caller/reference searches.
