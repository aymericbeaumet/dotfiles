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

  # tools
  export BAT_THEME="Nord"
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"

  # rekki
  if [ -x "$HOME/.rekki/bin/rekki" ]; then
    eval "$("$HOME/.rekki/bin/rekki" shellenv)"
    export REKKI_CLI_NO_REPORTING=true
    export REKKI_CLI_STACKTRACE=true
  fi
fi
