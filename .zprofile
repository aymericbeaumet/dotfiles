# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

export BAT_THEME="Nord"
export CGO_CFLAGS_ALLOW="-Xpreprocessor"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"

if [ -z "$HOMEBREW_PREFIX" ]; then
  eval $(/opt/homebrew/bin/brew shellenv)
fi

if [ -z "$CARGO_HOME" ]; then
  export CARGO_HOME="$HOME/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"
fi

if [ -z "$GOPATH" ]; then
  export GOPATH="$HOME/.go"
  export PATH="$GOPATH/bin:$PATH"
fi
