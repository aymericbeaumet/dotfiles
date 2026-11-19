# VoiceInk dictation

`Brewfile` installs the official VoiceInk app. Its prebuilt distribution needs a
license after the trial; activate it in **VoiceInk Pro**. Licensing state stays
outside the repository.

The MacBook Pro has a 14-core M4 Pro and 48 GB RAM. Parakeet Ultra is VoiceInk's
[recommended local Apple Silicon model](https://tryvoiceink.com/docs/recommended-models)
for English and European languages, including French. The **Local English + French**
mode uses it with automatic language detection and real-time transcription.

The Ollama provider points at the local `ministral-3:8b` model for text
enhancement, enabled in this mode. Parakeet remains a separate speech model; its
files are installed by the dotfiles setup. See [Ollama setup](ollama.md) for service
and model management.

Press **Alt/Option + Space** once to start recording and again to stop, enhance,
and paste. The global shortcut uses Toggle mode; no secondary recording shortcut
is assigned. On the external keyboards, Karabiner swaps the physical left Alt and
Command/Windows keys, so use the key that emits Option (physical Windows/Command
on those keyboards). The MacBook's Option key works normally. Model prewarming
keeps inference ready without recording audio.

## Configuration and setup

`~/.config/voiceink` links to this repository's `.config/voiceink/`. VoiceInk itself
uses macOS preferences, so `scripts/configure-voiceink.mjs` applies the selected
settings from `settings.json`; it preserves unrelated preferences, other Modes,
and undeclared fields such as the current mode's prompt and icon.
It restarts VoiceInk when the app is running. Apply edits with:

```sh
rtk proxy node scripts/configure-voiceink.mjs
```

On macOS, `setup.sh` installs the pinned model artifacts and applies this config
after creating the symlink. `--no-voiceink` skips those steps. Linux skips them.
The model installer verifies existing files and downloads missing or corrupt ones
from the pinned revisions in `models.json`. Models live outside Git under
`~/Library/Application Support/FluidAudio/Models/parakeet-ultra/` and `silero-vad/`.
The SDK strips `-coreml` from repository names for its cache directory names.

Microphone priority is **Sennheiser Profile → Shure MV7 → Studio Display → MacBook**.
The Audio page shows the active microphone and automatically skips disconnected
devices. Run the config script with each microphone connected so VoiceInk can
remember its identifier. To provide IDs for disconnected inputs, use the ignored
`microphones.local.json` file in the same config directory. It maps microphone
names to arrays of device IDs. Device enumeration never captures audio or changes
the system's default input.

## Custom words

Add words directly under **Dictionary → Vocabulary** and exact corrections under
**Word Replacements**. To transfer the dictionary, export it as `.config/voiceink/dictionary.json`,
which Git ignores. Import it through **Dictionary → Dictionary Settings → Import**, choosing Merge.
In VoiceInk 2.27, Vocabulary's local phonetic correction ignores accented terms;
use Word Replacements for French names with accents and recurring French errors.
Export from that panel to bring GUI edits back into the JSON file. The JSON is an
import/export format, not a live database; VoiceInk's dictionary and transcription
history remain in its own Application Support directory.

[VoiceInk audio input](https://tryvoiceink.com/docs/audio-input) documents priority
selection; [shortcuts](https://tryvoiceink.com/docs/shortcuts) documents recording modes.
