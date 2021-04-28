# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

if [ -z "$RIPGREP_CONFIG_PATH" ]; then
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
fi

if [ -z "$BREW_PATH" ]; then
  BREW_PATH='/usr/local'
  export PATH="$BREW_PATH/bin:$BREW_PATH/sbin:$PATH"
fi

if [ -z "$CARGO_HOME" ]; then
  export CARGO_HOME="$HOME/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"
fi

if [ -z "$GOPATH" ]; then
  export GOPATH="$HOME/.go"
  export PATH="$GOPATH/bin:$PATH"
fi
