# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# homebrew
export HOMEBREW_NO_ENV_HINTS=true
eval $(/opt/homebrew/bin/brew shellenv)

# go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# rust/cargo
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"
export PATH="$(brew --prefix rustup)/bin:$PATH"

# bat
export BAT_THEME="Nord"

# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
