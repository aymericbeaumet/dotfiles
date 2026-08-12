# Dotfiles agent guide

This is the canonical repository instruction file. Keep project guidance here in standard
`AGENTS.md` form; do not add a parallel `CLAUDE.md` or copy these instructions into a
client-specific config.

## Working rules

- Prefix shell commands with `rtk` so command output stays concise.
- Preserve unrelated working-tree changes. This is a live home-directory configuration repo.
- Every commit message MUST follow the latest published
  [Conventional Commits specification](https://www.conventionalcommits.org/).
- Run `scripts/check.sh` after material changes. If an unrelated pre-existing change blocks the
  full check, run the relevant focused validators and report the blocker.
- Cross-platform user-facing CLIs belong in `.config/mise/config.toml`. Prefer a mise registry
  short name, then `aqua:`, `ubi:`, `npm:`, or `pipx:`.
- Keep client-neutral guidance and Agent Skills under `AGENTS.md` and `.agents/skills/`.
  Client-specific settings may adapt native hooks, MCP syntax, or discovery paths, but must not
  become a second source of behavioral instructions.
- Semble is the only globally configured MCP server for Claude, Codex, and OpenCode.

## Supported machines

This repo is the single source of truth for two machines. A shared change that works on only one
is a bug.

- **macOS:** MacBook Pro, Apple M4 Pro (`arm64`), with the only GUI/display environment.
- **Linux:** Minisforum MS-A2, Debian (`x86_64`), headless.

Aim for identical behavior on both. Never hardcode an architecture or Homebrew-only path for a
shared tool. Prefer feature detection (`command -v`) and explicitly gate unavoidable divergence:

```bash
if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS-only
fi

if command -v apt-get >/dev/null 2>&1; then
  # Debian/Ubuntu-only
fi
```

GUI apps and macOS-only tooling belong in `Brewfile`; `brew bundle` must never run on Linux.
System bootstrappers and OS packages belong in `setup.sh`. Route clipboard and URL-opening work
through `scripts/clip.sh` and `scripts/open-url.sh` instead of calling `pbcopy` or `open`
directly.

`setup.sh` must remain safe to rerun from either machine and keep its existing Darwin/Debian
guards for Homebrew, macOS defaults, and APT.
