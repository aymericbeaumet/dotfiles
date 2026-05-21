---
name: peon-ping-toggle
description: Toggle peon-ping sound notifications on/off. Use when user wants to mute, unmute, pause, or resume peon sounds during a session.
---

# peon-ping-toggle

Toggle peon-ping sounds on or off.

## Toggle sounds

```bash
peon toggle
```

This prints either:
- `peon-ping: sounds paused` — sounds are now muted
- `peon-ping: sounds resumed` — sounds are now active

## What this toggles

Toggles the **master audio switch** (`enabled` config). When disabled:
- Sounds stop playing
- Desktop notifications also stop
- Mobile notifications also stop

**For notification-only control**, use `/peon-ping-config` to set `desktop_notifications: false`. This keeps sounds playing while suppressing desktop popups.
