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

  # ***REMOVED***
  eval "$("$HOME/.***REMOVED***/bin/***REMOVED***" shellenv)"
  export ***REMOVED***_CLI_NO_REPORTING=true
  export ***REMOVED***_CLI_STACKTRACE=true
fi
