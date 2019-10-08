# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# Sourced here to make `z` available in login shells
source '/usr/local/opt/z/etc/profile.d/z.sh'

# gpg
export GPG_TTY="$(tty)"

# homebrew + coreutils
BREW_PATH='/usr/local'
if [[ -z "$TMUX" ]]; then
  export PATH="$BREW_PATH/opt/coreutils/libexec/gnubin:$BREW_PATH/bin:$BREW_PATH/sbin:$PATH"
fi

# cargo
export CARGO_HOME="$HOME/.cargo"
if [[ -z "$TMUX" ]]; then
  export PATH="$CARGO_HOME/bin:$PATH"
fi

# go
export GOPATH="$HOME/.go"
if [[ -z "$TMUX" ]]; then
  export PATH="$GOPATH/bin:$PATH"
fi

# n
export N_PREFIX="$HOME/.n"
if [[ -z "$TMUX" ]]; then
  export PATH="$N_PREFIX/bin:$PATH"
fi

# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
