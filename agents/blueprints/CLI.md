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
| Homebrew tap | `aymericbeaumet/homebrew-tap` |
| Default branch | `main` |
| Tags | `vX.Y.Z` |
| Commits | [Conventional Commits](https://www.conventionalcommits.org/) |
| Agent branches | `ab/<slug>` |

Keep crate `authors`, `license`, `repository`, clap `author`, the MIT copyright
line, README install URLs, and Homebrew `homepage` identical.

## Layout

Prefer squeeze's flat crates (no `src/`):

```text
.
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── ci.yml
│       ├── nightly.yml
│       └── release.yml
├── AGENTS.md
├── Cargo.lock
├── Cargo.toml
├── Formula/<bin>.rb
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

Skip `Formula/` and `nightly.yml` until the Homebrew tap should publish the
tool.

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

Allow Homebrew and CI to override the reported version:

```rust
const VERSION: &str = match option_env!("<NAME>_VERSION") {
    Some(v) => v,
    None => env!("CARGO_PKG_VERSION"),
};
```

Pass that constant to clap's `version`.

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

Use `readme.md`. Open with the name, a CI badge, and one sentence.

Required sections:

1. **Install** — Homebrew tap, `cargo install --git`, from source.
2. **Getting Started** — stdin examples that show the actual output.
3. **Integrations** — only if the tool is meant to be piped from vim/tmux/shell.
4. **Development** — `cargo run` and `cargo test` / `watchexec`.

Homebrew:

```shell
brew tap aymericbeaumet/tap
brew install <bin>
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

Triggers: `pull_request`, `push` to `main`, daily `schedule`.

Jobs:

| Job | What |
|---|---|
| `check` | `dtolnay/rust-toolchain@stable` with `rustfmt, clippy`, `Swatinem/rust-cache`, `cargo fmt --all -- --check`, `cargo clippy --all-targets -- --deny warnings`, `cargo build --release`, `cargo test --all-targets` |
| `msrv` | toolchain = crate `rust-version`; `cargo build` and `cargo test --all-targets` |
| `test` | matrix `ubuntu-latest`, `macos-latest`, `windows-latest` |
| `docs` | `RUSTDOCFLAGS=-D warnings` rustdoc for `<lib>` and `<cli>` |

### `.github/workflows/release.yml`

On `v*` tags, `contents: write`:

1. Parse version from the tag (`v` prefix stripped).
2. Fail if it does not match the library crate `version`.
3. `gh release create "$tag" --title "$tag" --generate-notes`.
4. SHA256 the tag archive.
5. Update `aymericbeaumet/homebrew-tap` with
   `mislav/bump-homebrew-formula-action` and `HOMEBREW_TAP_TOKEN`.

### `.github/workflows/nightly.yml`

On push to `main`, rewrite `Formula/<bin>-nightly.rb` in the tap. Version
`nightly-YYYYMMDD-<sha7>`, `conflicts_with` the stable formula, and set
`<NAME>_VERSION` during `cargo install`.

### `.github/dependabot.yml`

Weekly `cargo` and `github-actions` updates. Commit prefixes `deps` and `ci`.

## Homebrew

In-repo `Formula/<bin>.rb` is the template the tap should converge to:

```ruby
class <Bin> < Formula
  desc "<one line>"
  homepage "https://github.com/aymericbeaumet/<name>"
  url "https://github.com/aymericbeaumet/<name>/archive/refs/tags/vX.Y.Z.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/aymericbeaumet/<name>.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "<cli>")
  end

  test do
    # pipe or exec <bin> with a stable assertion
  end
end
```

Install from the CLI crate path, not the workspace root. The formula `test`
must exercise the installed binary without the network.

## Release

1. Bump every crate `version` together.
2. `make check`.
3. Commit, then tag `vX.Y.Z` on `main` and push the tag.
4. Confirm the GitHub release and the tap formula update.

Do not hand-edit the tap formula when the release workflow owns it.

## Reference

When a detail is missing, open
[aymericbeaumet/squeeze](https://github.com/aymericbeaumet/squeeze) and copy the
matching file. Do not import squeeze finders, fixtures, or product flags.
