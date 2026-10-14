# Flash status bar

Names, colours, links, and hovers live in `.config/flash/flash.toml`. A plugin
or a source prints the value beside a name and nothing else.

The feed is `#[label]aggr` plus `#{flash.plugin.feed.label}`, the rotating
headline. Hovering `aggr` opens `[popup.feed]`, the resident newsboat list.
Hovering the headline opens `[popup.feed-article]` on that item's text. Flash
passes the headline's link as `$FLASH_STATUS_LINK`. The reader takes the body
from `~/.cache/newsboat/flash-feed.db` and, when that body is only a link,
from the original page. It does not open a second newsboat. CPU, MEM, DSK, NET, and BAT
are the same shape inside `#[popup=btop]`: `#[label]CPU` plus
`#{p-3:flash.plugin.cpu.label}`. `p-3` keeps a percentage three cells wide
and `p-4` does the same for the network rate. Battery charge is not padded.

## Quotas

Cld, Cdx, and Grk are owned by this repository. Flash draws them. It does not
fetch them.

The names, the `#[label]` colour, the usage-page links, and the tokscale hover
are in `.config/flash/flash.toml`. `scripts/ai-quota` prints only the metric
(`6%↻22h`). Three status sources call it, one provider each.

A reading stays until a newer sample replaces it. A missing file, a failed
fetch, or an expired Grok token keeps the last percentage. Every window is
weekly, so once a stored reset passes the window rolls forward: the quota shows
full and the countdown points at the following reset. An em dash means that
provider has never produced a weekly window.

Grok readings stop refreshing when the access token in `~/.grok/auth.json`
expires. `ai-quota` never uses the refresh token; running `grok` renews it.

Claude comes from `~/.cache/claude/rate-limits.json`, written by
`scripts/claude-statusline.sh` after a Claude Code response. The quota command
does not read Claude credentials, the login keychain, or Anthropic. Codex comes
from `codex app-server`. Grok is a read-only billing request with the token
already in `~/.grok/auth.json`; the command never writes that file. State is
`~/.cache/ai-quota.json`, mode 0600, percentages and reset times only.

The first run copies a still-present aiproviders cache, so removing that plugin
does not blank a number the bar has already shown.
