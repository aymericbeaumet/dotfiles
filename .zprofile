# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

export BAT_THEME="Nord"
export CGO_CFLAGS_ALLOW="-Xpreprocessor"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"

if [ -z "$HOMEBREW_PREFIX" ]; then
  # homebrew
  eval $(/opt/homebrew/bin/brew shellenv)

  # node/npm
  export PATH="/opt/homebrew/opt/node@16/bin:$PATH"
  export PATH="$(npm config get prefix):$PATH"

  # go
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"

  # rust/cargo
  export CARGO_HOME="$HOME/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"

  # rekki
  eval "$("$HOME/.rekki/bin/rekki" shellenv)"
fi
