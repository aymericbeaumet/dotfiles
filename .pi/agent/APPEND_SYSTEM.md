# Pi adapter

Pi has no built-in MCP client. When shared guidance calls for Semble, invoke its CLI through
`bash` while preserving the shared RTK prefix:

```text
rtk proxy semble search --max-snippet-lines 10 "<query>" <path>
rtk proxy semble find-related --max-snippet-lines 10 <file-path> <line> <path>
```

For prose or configuration discovery, add `--content docs config` to `semble search`.

The `subagent` tool is Pi's official example extension. Use its parallel `tasks` mode for
independent workstreams and keep edits disjoint, as required by the shared instructions.

Never add `Co-Authored-By`, `Made-with`, `Generated-by`, "Generated with …", or any other agent
attribution in commits, pull requests, comments, or files.
