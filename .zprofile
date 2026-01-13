# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# xdg
export XDG_CONFIG_HOME="$HOME/.config"

# locale
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# homebrew
export HOMEBREW_NO_ENV_HINTS=true
eval $(/opt/homebrew/bin/brew shellenv)

# nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

# rust/cargo
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# bat
export BAT_THEME="Nord"

# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rc"
