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
| Workflow-specific scope and stopping rules | `.agents/skills/*/SKILL.md` |
| Native discovery and hooks | Client adapters described in `.agents/README.md` |

The client instruction symlinks and Claude's instruction hook distribute the shared defaults.
Editing those defaults therefore changes behavior across clients without copying a prompt into
each client's settings. Client-managed system skills and installed plugin caches are outside the
tracked shared skill tree.

Codex's personal `config.toml` is intentionally ignored. OpenCode and Pi have tracked model choices
and compatibility checks in `scripts/check.sh`. A prompting update does not establish a reason to
change those models, reasoning levels, permissions, or transport settings. Verify native support
before translating API guidance into a client setting.

## Reviewing changes

Review the affected skills and adapters with the shared defaults. Check that a request retains its
scope through preparation, approval, execution, and completion: prior approval should still count,
an explicit inspection-only request should stay read-only, and an unresolved decision should block
only dependent work. Required checks still apply; passing checks need another run only when the
relevant state changes or a concrete concern remains.

Run `scripts/check.sh` after material changes. It validates configuration syntax, skill metadata,
instruction symlinks, and repository contracts. Review prose behavior separately; those checks do
not prove that an instruction will produce the intended decisions.
