# Agent guidance maintenance

The [OpenAI model guide](https://developers.openai.com/api/docs/guides/latest-model#prompting-best-practices)
informed the shared collaboration defaults: task completion, authorization, instruction conflicts,
writing, delegation, and verification. These are portable workflow choices. API migration settings
need a separate compatibility check against the client that will use them.

## Configuration boundaries

| Concern | Maintained source |
|---|---|
| Collaboration across repositories | `.agents/AGENTS.md` |
| Dotfiles development constraints | Root `AGENTS.md` |
| Project documentation and context for humans and agents | `./docs/` |
| Workflow-specific scope and stopping rules | `.agents/skills/*/SKILL.md` |
| Native discovery and hooks | Client adapters described in `.agents/README.md` |

The client instruction symlinks and Claude's instruction hook distribute the shared defaults.
Editing those defaults therefore changes behavior across clients without copying a prompt into
each client's settings. Client-managed system skills and installed plugin caches are outside the
tracked shared skill tree.

Project guidance and documentation are maintained throughout development. Completed work and
corrections feed concise, reusable instructions into the applicable `AGENTS.md`, while explanations,
decisions, and broader context belong in `./docs`. Existing content is revised as understanding
changes; transient session state stays in handouts.

The retained clients are Claude Code and Codex. Codex's personal `config.toml` is intentionally
ignored; Claude's shared settings and both clients' hook adapters are tracked. A prompting update
does not establish a reason to change models, reasoning levels, permissions, or transport settings.
Verify native support before translating API guidance into a client setting.

Use native client retries and lightweight hooks for shared instructions, worktree policy, and pane
state. Project formatting and editor formatting own file rewrites. Avoid maintaining a parallel
retry loop or applying a global formatter policy after each agent edit.

Git workflow handoffs preserve the checkout the user actually requested: source branch, HEAD,
pending changes, and remote destination. The bonsai skill owns the handoff contract. A new worktree
must not substitute the default branch for existing work or silently change the branch being pushed.

## Reviewing changes

Review the affected skills and adapters with the shared defaults. Check that a request retains its
scope through preparation, approval, execution, and completion: prior approval should still count,
an explicit inspection-only request should stay read-only, and an unresolved decision should block
only dependent work. Required checks still apply; passing checks need another run only when the
relevant state changes or a concrete concern remains.

Run `scripts/check.sh` after material changes. It validates configuration syntax, skill metadata,
instruction symlinks, and repository contracts. Review prose behavior separately; those checks do
not prove that an instruction will produce the intended decisions.
