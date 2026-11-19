# Local models with Ollama

Ollama is macOS-only in these dotfiles, installed by the `ollama` Homebrew formula.
`setup.sh` starts it through `brew services start ollama`, waits for the local API,
and installs missing models from `.config/ollama/models.txt`. The service starts
again at login. `--no-ollama` skips service startup and model installation; Linux
skips the entire section. Ollama does not belong in the mise configuration.

`~/.config/ollama` links to this repository's configuration directory. Add explicit
model tags there, one per line, then run:

```sh
rtk proxy node scripts/configure-ollama.mjs
```

The initial model is [`ministral-3:8b`](https://ollama.com/library/ministral-3:8b):
an approximately 6 GB quantized multilingual model, including English and French,
under Apache 2.0. Setup keeps installed models and does not remove models omitted
from the list. To update the contents of an already-installed tag, run
`rtk proxy ollama pull ministral-3:8b` explicitly.

The API listens on `http://127.0.0.1:11434`; the setup helper always targets that
local endpoint. Homebrew manages the launch agent and its environment. Model weights
and Ollama's own state remain under `~/.ollama`, outside the repository.

```sh
rtk proxy brew services info ollama
rtk proxy ollama list
rtk proxy ollama run ministral-3:8b
```

## VoiceInk and Parakeet

VoiceInk's Ollama provider is configured for `ministral-3:8b` at the local URL.
The local dictation Mode uses it for text enhancement after Parakeet Ultra's
speech recognition. Alt/Option + Space toggles recording.

Ollama 0.40.16 has audio-input support for certain model architectures, but no
supported Parakeet Ultra/Core ML backend. It cannot serve the Parakeet model used
by VoiceInk. Parakeet is already installed independently of VoiceInk's downloader:
`scripts/install-voiceink-models.mjs` manages its pinned files and verifies their
checksums. VoiceInk only loads those shared model files. See
[voice dictation](voice-dictation.md) for that configuration.

References: [Ollama audio API](https://docs.ollama.com/api/openai-compatibility),
[model backends](https://github.com/ollama/ollama/blob/v0.40.16/mlxrunner/model/architectures/architectures.go),
and [VoiceInk local models](https://tryvoiceink.com/docs/local-models).
