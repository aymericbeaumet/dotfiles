---
name: peon-ping-use
description: Set which voice pack (character voice) plays for the current chat session. Use when user wants a specific character voice like GLaDOS, Peon, or Kerrigan for this conversation.
---

# peon-ping-use

Set which voice pack (character voice) plays for the current chat session.

## Usage

### 1. List available packs

```bash
peon packs list
```

### 2. Get session ID

The session ID is available in environment variables — check `CLAUDE_SESSION_ID`, `CODEX_SESSION_ID`, or similar. If empty, use `"default"` as the key.

### 3. Update config to enable session_override mode

Read `~/.openpeon/config.json` and set `pack_rotation_mode` to `"session_override"`. If the requested pack is not in `pack_rotation`, add it.

### 4. Update state to assign pack to this session

Read `~/.openpeon/.state.json` and update the `session_packs` object to map the session ID to the requested pack:

```json
{
  "session_packs": {
    "SESSION_ID_HERE": "pack_name_here"
  }
}
```

### 5. Confirm to user

Report: `Voice set to [PACK_NAME] for this session`

## Error handling

- **Pack not found**: List available packs and ask user to choose one
- **No session ID**: Use `"default"` as the session key
