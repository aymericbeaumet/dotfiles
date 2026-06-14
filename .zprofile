# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# xdg
export XDG_CONFIG_HOME="$HOME/.config"

# locale
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Deduplicate PATH early (before any PATH modifications)
typeset -U path
path=(${path:#*\#\{HOME\}*})

# homebrew (support both Apple Silicon and Intel)
export HOMEBREW_NO_ENV_HINTS=true
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# local user bin
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

# postgresql client (libpq is keg-only)
[[ -d /opt/homebrew/opt/libpq/bin ]] && export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# go
export GOPATH="$HOME/go"
[[ -d "$GOPATH/bin" ]] && export PATH="$GOPATH/bin:$PATH"
[[ -d /usr/local/go/bin ]] && export PATH="/usr/local/go/bin:$PATH"

# gors
export GORSPATH="$HOME/gors"
[[ -d "$GORSPATH/bin" ]] && export PATH="$GORSPATH/bin:$PATH"

# rust/cargo
export CARGO_HOME="$HOME/.cargo"
[[ -d "$CARGO_HOME/bin" ]] && export PATH="$CARGO_HOME/bin:$PATH"
[[ -d /opt/homebrew/opt/rustup/bin ]] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
[[ -d /usr/local/opt/rustup/bin ]] && export PATH="/usr/local/opt/rustup/bin:$PATH"

# bat
export BAT_CONFIG_PATH="$HOME/.config/bat/config"

# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
