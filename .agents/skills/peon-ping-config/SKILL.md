---
name: peon-ping-config
description: Update peon-ping configuration — volume, pack rotation, categories, active pack, and other settings. Use when user wants to change peon-ping settings like volume, enable round-robin, add packs to rotation, toggle sound categories, or adjust any config.
---

# peon-ping-config

Update peon-ping configuration settings.

## Config location

The config file is at `~/.openpeon/config.json`.

## Available settings

- **volume** (number, 0.0–1.0): Sound volume
- **default_pack** (string): Current sound pack name (e.g. `"peon"`, `"sc_kerrigan"`, `"glados"`)
- **enabled** (boolean): Master on/off switch
- **pack_rotation** (array of strings): List of packs to rotate through per session. Empty `[]` uses `default_pack` only.
- **pack_rotation_mode** (string): `"random"` (default) picks a random pack each session. `"round-robin"` cycles through in order. `"session_override"` uses explicit per-session assignments from `/peon-ping-use`.
- **categories** (object): Toggle individual sound categories:
  - `session.start`, `task.acknowledge`, `task.complete`, `task.error`, `input.required`, `resource.limit`, `user.spam` — each a boolean
- **disabled_sounds** (object): Disable specific sound files within a pack, keyed by pack name → category → array of filenames.
  Prefer the CLI: `peon sounds list [pack]`, `peon sounds disable <category> <file>`, `peon sounds enable <category> <file>`
- **annoyed_threshold** (number): How many rapid prompts trigger user.spam sounds
- **annoyed_window_seconds** (number): Time window for the annoyed threshold
- **silent_window_seconds** (number): Suppress task.complete sounds for tasks shorter than this many seconds
- **desktop_notifications** (boolean): Toggle notification popups independently from sounds (default: `true`)
- **use_sound_effects_device** (boolean): Route audio through macOS Sound Effects device (`true`) or default output (`false`)

## How to update

1. Read the config file using the Read tool
2. Edit the relevant field(s) using the Edit tool
3. Confirm the change to the user

## CLI shortcuts

```bash
peon volume 0.3            # Set volume to 30%
peon toggle                # Toggle sounds on/off
peon rotation round-robin  # Set rotation mode
peon notifications off     # Disable desktop popups
peon packs list            # List available packs
peon packs bind <pack>     # Bind pack to current directory
peon packs unbind          # Remove binding
peon packs bindings        # List all bindings
```
