# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# Sourced here to make `z` available in login shells
source '/usr/local/opt/z/etc/profile.d/z.sh'

if [[ -z "$TMUX" ]]; then

  # gpg
  export GPG_TTY="$(tty)"

  # homebrew + coreutils
  BREW_PATH='/usr/local'
  export PATH="$BREW_PATH/opt/coreutils/libexec/gnubin:$BREW_PATH/bin:$BREW_PATH/sbin:$PATH"

  # krew
  KREW_ROOT="$HOME/.krew"
  export PATH="$KREW_ROOT/bin:$PATH"

  # cargo
  export CARGO_HOME="$HOME/.cargo"
  export PATH="$CARGO_HOME/bin:$PATH"

  # go
  export GOPATH="$HOME/.go"
  export PATH="$GOPATH/bin:$PATH"

  # n
  export N_PREFIX="$HOME/.n"
  export PATH="$N_PREFIX/bin:$PATH"

  # ripgrep
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"

fi
