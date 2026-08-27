# CLI project blueprint

Reusable spec for a public Rust CLI. Inspired by
[squeeze](https://github.com/aymericbeaumet/squeeze). Copy the structure, not
the product.

Use this when creating or aligning a standalone command-line tool. Substitute
`<name>` (repo), `<bin>` (installed command), `<lib>` (library crate), and
`<cli>` (binary crate, usually `<name>-cli`).

## Identity

| Field | Value |
|---|---|
| Author | Aymeric Beaumet `<hi@aymericbeaumet.com>` |
| Site | https://aymericbeaumet.com |
| GitHub | `aymericbeaumet/<name>` |
| License | MIT |
| Default branch | `main` |
| Tags | `vX.Y.Z` (minted by CI, never by hand) |
| Commits | [Conventional Commits](https://www.conventionalcommits.org/) |
| Agent branches | `ab/<slug>` |

Keep crate `authors`, `license`, `repository`, clap `author`, the MIT copyright
line, and README install URLs identical.

## Layout

Prefer squeeze's flat crates (no `src/`):

```text
.
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── AGENTS.md
├── Cargo.lock
├── Cargo.toml
├── LICENSE
├── Makefile
├── readme.md
├── <lib>/
│   ├── Cargo.toml
│   ├── lib.rs
│   ├── benches/            # optional
│   └── tests/
└── <cli>/
    ├── Cargo.toml
    ├── main.rs
    └── tests/
        ├── cli.rs
        └── cli_hardening.rs
```

Split a library crate from the binary crate even for a small tool. The library
owns behavior and tests; the binary owns clap, I/O, and process exit.

## License

Track `LICENSE` as MIT. GitHub license detection expects that name.

```text
MIT License

Copyright (c) Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

Set `license = "MIT"` on every crate. Do not add a second license file.

## Rust workspace

Root `Cargo.toml`:

```toml
[workspace]
members = ["<lib>", "<cli>"]
resolver = "3"

[profile.dev]
opt-level = 0

[profile.release]
codegen-units = 1
lto = "fat"
opt-level = 3
panic = "abort"
strip = true
```

Every member crate:

- `edition = "2024"` (or the current edition squeeze uses)
- `rust-version` pinned and identical across crates, `Makefile`, and the CI MSRV job
- `version` identical across crates
- `authors`, `license`, `repository`, `readme = "../readme.md"`
- focused `keywords` and `categories` (`command-line-utilities` on the CLI crate)

Library crate:

```toml
[lib]
name = "<lib>"
path = "lib.rs"
```

Binary crate:

```toml
[[bin]]
name = "<bin>"
path = "main.rs"

[dependencies]
clap = { version = "4", features = ["derive"] }
env_logger = "0.11"
<lib> = { path = "../<lib>" }

[dev-dependencies]
assert_cmd = "2"
predicates = "3"
```

Commit `Cargo.lock`. Ignore `target/`, editor dirs, `.DS_Store`, and
`proptest-regressions/` if proptest is used. Do not add `rustfmt.toml` or
`clippy.toml` unless the default is wrong.

Use clap's plain `version` (from `CARGO_PKG_VERSION`). The release workflow
stamps the computed version into `Cargo.toml` before building, so no
`option_env!` override is needed.

## CLI conventions

Unix filter first:

- No `INPUT` arguments: read stdin. Arguments are files or quoted globs.
- Results on stdout, diagnostics on stderr.
- `main() -> ExitCode`. Usage errors exit `2` (clap). Other failures exit `1`.
- Treat broken pipe as success so `… | head` is quiet.
- `env_logger::init()` and clap derive (`name`, `version`, `author`, `about`).
- Keep help text lowercase and short, like squeeze.
- Prefer long flags; add a short flag only for high-frequency options.
- Validate flags before any early return so bad values fail even when unused.

Do not call `pbcopy` or `open` directly if those features exist. Route through
the same abstractions used in squeeze (`arboard` / `open`, with a Linux
clipboard helper if clipboard support is required).

## Configuration layering

When the tool needs configuration, layer it with figment, low to high
precedence:

1. compiled defaults
2. `~/.config/<name>/config.toml` (personal, global)
3. `<repo>/.<name>.toml` (checked in, team policy) — when the tool is
   repo-scoped
4. `git config <name>.*` (per-clone personal overrides) — when the tool is
   git-aware
5. `<NAME>_*` environment variables, with `__` nesting sections
   (`<NAME>_SECTION__KEY=…`)
6. CLI flags

Every layer uses the same key names. Skip layers 3–4 for tools that are not
repo- or git-scoped.

## Tests

- Library: unit tests next to the code, integration tests under `<lib>/tests/`.
  Add proptest or dedicated hardening tests for parsers and untrusted input.
- CLI: `assert_cmd` + `predicates` covering `--help`, `--version`, the happy
  path, and flag combinations.
- Hardening: invalid UTF-8 must not abort a stream, broken pipe is success,
  missing files fail clearly, empty stdin is success.
- `cargo test --all-targets` must pass on Linux, macOS, and Windows.

## Makefile

`make` / `make check` is the local equivalent of CI:

```make
check: fmt-check lint test doc-check

fmt-check:
	cargo fmt --all -- --check

lint:
	cargo clippy --all-targets -- --deny warnings

test:
	cargo test

doc-check:
	RUSTDOCFLAGS="-D warnings" cargo doc -p <lib> --no-deps --all-features
	RUSTDOCFLAGS="-D warnings" cargo doc -p <cli> --no-deps --all-features
```

Also provide `build`, `release`, `fmt`, `doc`, `clean`, `install`
(`cargo install --path <cli>`), `watch` (`watchexec --clear --restart 'cargo test'`),
`msrv`, `update`, `outdated`, and `audit`. Keep the MSRV target on the same
toolchain as `rust-version`.

## README

Use `readme.md`. Open with the name, the release-workflow badge
(`actions/workflows/release.yml/badge.svg` — ci does not run on `main`
pushes), and one sentence.

Required sections:

1. **Install** — mise first, then `cargo install --git`.
2. **Getting Started** — stdin examples that show the actual output.
3. **Integrations** — only if the tool is meant to be piped from vim/tmux/shell.
4. **Development** — `cargo run` and `cargo test` / `watchexec`.

mise:

```shell
mise use -g github:aymericbeaumet/<name>
```

Cargo:

```shell
cargo install --git https://github.com/aymericbeaumet/<name> <cli>
```

## Project AGENTS.md

Keep it short and harness-neutral:

```markdown
# <name> agent guide

- Run `make check` after material changes.
- Every commit message MUST follow the latest published
  [Conventional Commits specification](https://www.conventionalcommits.org/).
- Keep reusable logic in `<lib>` and process I/O in `<cli>`.
- `cargo fmt`, `cargo clippy --all-targets -- --deny warnings`, and
  `cargo test --all-targets` must stay clean.
- Do not add `CLAUDE.md` or other client-specific instruction files.
```

## GitHub Actions

### `.github/workflows/ci.yml`

Triggers: `pull_request`, `workflow_dispatch`, `workflow_call` — no `push`;
release.yml calls ci on every push to `main`, so a push trigger would run it
twice.

Jobs:

| Job | What |
|---|---|
| `test` | 6-leg native matrix (below); `dtolnay/rust-toolchain@stable` with `rustfmt, clippy`, `Swatinem/rust-cache`, `cargo fmt --check` (one linux leg only), `cargo clippy --all-targets -- --deny warnings`, `cargo test --all-targets` |
| `msrv` | toolchain = crate `rust-version`; `cargo build` and `cargo test --all-targets` |
| `docs` | `RUSTDOCFLAGS=-D warnings` rustdoc for `<lib>` and `<cli>` |

Test matrix — every release target has a native runner, so nothing is ever
cross-compiled:

| Leg | Runner |
|---|---|
| `linux-amd64` | `ubuntu-latest` |
| `linux-arm64` | `ubuntu-24.04-arm` |
| `darwin-amd64` | `macos-15-intel` |
| `darwin-arm64` | `macos-latest` |
| `windows-amd64` | `windows-latest` |
| `windows-arm64` | `windows-11-arm` |

### `.github/workflows/release.yml`

Every green push to `main` publishes a real release. Triggers: `push` to
`main`, `workflow_dispatch`. `permissions: contents: write` and
`concurrency: group: release` (no cancel-in-progress) so concurrent pushes
serialize and version computation never races.

Jobs, in order:

1. `test` — `uses: ./.github/workflows/ci.yml`. Nothing builds or publishes
   unless the full suite is green on all six platforms.
2. `version` — checkout with `fetch-depth: 0`; compute the next semver from
   Conventional Commits since the latest `v*` tag: `!`/`BREAKING CHANGE` →
   major, `feat` → minor, anything else → patch (always releases). With no
   tags yet, seed from the crate `version` in `Cargo.toml`. Do **not** push a
   tag here — a failed build must not burn the version number.
3. `build` — needs `test` + `version`; the same 6-leg native matrix as ci.
   Stamp the computed version into `Cargo.toml` with `perl -pi` (portable
   across BSD/GNU sed and Windows; never committed), build **without**
   `--locked` (the stamp would fail a locked build; resolution is unchanged),
   `cargo build --release`, then package the binary alone:
   `<bin>-{linux,darwin,windows}-{amd64,arm64}` as `.tar.gz` (`.zip` on
   Windows). Upload as artifacts.
4. `release` — download all artifacts, write `SHA256SUMS`, then
   `gh release create "vX.Y.Z" --target "$GITHUB_SHA" --generate-notes` with
   every asset. This mints the tag and the release atomically, only after
   every build succeeded.

### `.github/dependabot.yml`

Weekly `cargo` and `github-actions` updates. Commit prefixes `deps` and `ci`.

## mise

mise's `github` backend reads GitHub releases directly — a public repo needs
no registry submission at all:

```shell
mise use -g github:aymericbeaumet/<name>
```

Requirements and caveats:

- Asset names must be auto-detectable: use `linux`/`darwin`/`windows` and
  `amd64`/`arm64` in the file names (`<bin>-<os>-<arch>.tar.gz`). Ship the
  binary alone in each archive.
- The `ubi:` backend is deprecated (removed in mise 2027.1) — document and
  use `github:`.
- `mise x github:…` silently falls back to a same-named binary already on
  `PATH` (for example a `cargo install`ed copy) when the tool is not
  installed. Verify installs with `mise install` + `mise where`, not just
  `mise x … -- <bin> --version`.

## Release

Releases are continuous — never bump versions or push tags by hand:

1. Merge or push to `main`.
2. release.yml runs the full ci suite, then builds and publishes
   `vX.Y.Z` computed from the Conventional Commit messages since the last
   tag. A red suite means no release.
3. The crate `version` in `Cargo.toml` only seeds the very first release;
   after that, tags are the single source of truth.

Because commit types drive version bumps, commit messages must be accurate:
a `feat:` mislabeled as `chore:` ships as a patch.

## Reference

When a detail is missing, open
[aymericbeaumet/squeeze](https://github.com/aymericbeaumet/squeeze) and copy the
matching file. Do not import squeeze finders, fixtures, or product flags.
