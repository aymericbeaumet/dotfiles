# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

if [ -z "$HOMEBREW_PREFIX" ]; then
  # homebrew (support both arm64 and amd64 prefixes)
  export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
  eval $(brew shellenv)

  # go
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"

  # rust/cargo
  export CARGO_HOME="$HOME/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"

  # bat
  export BAT_THEME="Nord"

  # homebrew
  export HOMEBREW_NO_ENV_HINTS=true

  # ripgrep
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
fi
