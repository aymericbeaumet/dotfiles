# Dotfiles agent guide

This is the canonical repository instruction file. Keep project guidance here in standard
`AGENTS.md` form; do not add a parallel `CLAUDE.md` or copy these instructions into a
client-specific config.

Keep this `AGENTS.md` current with distilled instructions for agents. Maintain `./docs` as
documentation and context for both humans and agents. After non-trivial work or corrections,
integrate durable lessons into the appropriate surface and revise stale content.

## Working rules

- Prefix shell commands with `rtk` so command output stays concise.
- Preserve unrelated working-tree changes. This is a live home-directory configuration repo.
- Every commit message MUST follow the latest published
  [Conventional Commits specification](https://www.conventionalcommits.org/).
- Do not create pull requests for this repository. When publishing changes, validate and commit in
  a bonsai worktree, fast-forward the clean local `main` checkout, and push `main` directly to
  `origin` from the bonsai worktree. Never force-push.
- Run `scripts/check.sh` after material changes. If an unrelated pre-existing change blocks the
  full check, run the relevant focused validators and report the blocker.
- Cross-platform user-facing CLIs belong in `.config/mise/config.toml`. Prefer a mise registry
  short name, then `aqua:`, `ubi:`, `npm:`, or `pipx:`.
- Use Colima for local containers on macOS and native Docker Engine on Linux. Colima's macOS VM
  integration is an explicit Homebrew exception; keep the Docker CLI in mise. On Apple Silicon,
  prefer VZ, virtiofs, and Rosetta. Read `docs/containers.md` before changing runtime or storage.
- Keep client-neutral guidance and Agent Skills under `AGENTS.md` and `.agents/skills/`.
  Client-specific settings may adapt native hooks, MCP syntax, or discovery paths, but must not
  become a second source of behavioral instructions.
- When updating agent behavior, audit shared defaults, affected skills, and their client adapters
  together for conflicting scope, approval, and completion rules. Replace conflicting guidance
  at its canonical source; keep model selection and machine-local settings separate from prompting
  changes. Read `docs/agent-guidance.md` for the configuration boundaries.
- Claude Code and Codex CLI are the supported agent clients. Semble is their only globally
  configured MCP server; keep retired client state private and outside managed setup.
- For shell completion changes, read `docs/zsh-completion.md`. Validate actual Tab completion
  after deferred plugins load, including Git aliases and switching repositories.

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
