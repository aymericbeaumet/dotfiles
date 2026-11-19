# Flash status bar

Names, colours, links, and hovers live in `.config/flash/flash.toml`. A plugin
or a source prints the value beside a name and nothing else.

The feed is `#[label]aggr` plus `#{flash.plugin.feed.label}`, the rotating
headline. Hovering either one opens `[popup.feed]`, the resident newsboat
list. The parenthesised source after each headline is the item's RSS
`<source>`, which aggr writes as `youtube.com/@channel` or a domain; change how
a publisher reads in aggr, not here.
CPU, MEM, NET, and BAT are the same shape inside `#[popup=btop]`:
`#[label]CPU` plus `#{p-3:flash.plugin.sysinfo.cpu_label}`. `p-3` keeps a percentage
three cells wide and `p-4` does the same for the network rate. Battery charge
is not padded. Disks stay off the bar; the btop popup already shows them.

The clock is `#[popup=date]` and reads like `Thu Oct 15 18:55`: short weekday,
three-letter month, day, and 24-hour time. Clicking it opens the built-in
calendar.

## Quotas

Cld and Cdx are drawn by this repository and fetched by Flash's
aiproviders plugin.

The names, the `#[label]` colour, the usage-page links, and the tokscale hover
are in `.config/flash/flash.toml`. The plugin prints only the metric
(`6%↻22h`) as `#{flash.plugin.aiproviders.claude}` and `.codex`.

A reading stays until a newer sample replaces it. A failed fetch or an
expired token keeps the last percentage. Every window is
weekly, so once a stored reset passes the window rolls forward: the quota shows
full and the countdown points at the following reset. An em dash means that
provider has never produced a weekly window.

Each provider is read with what its own CLI already stored, so nothing in
this repository feeds the plugin. Claude is a read-only request to
Anthropic's usage endpoint with the OAuth access token Claude Code keeps in
the login keychain. Codex comes from `codex app-server`. The plugin
never refreshes or writes a token: Claude readings stop refreshing
when the access token expires, and running `claude` renews it.
tokscale behind the hover is optional and independent of the numbers. State is
`quotas.json` in the plugin's data directory
(`~/Library/Application Support/Flash/Plugins/aiproviders`), mode 0600,
percentages and reset times only.
