# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

setopt noglobalrcs

# homebrew
export BREW_DIR='/usr/local'
export PATH="$BREW_DIR/opt/coreutils/libexec/gnubin:$BREW_DIR/bin:$PATH:/usr/sbin:/sbin"
export MANPATH="$BREW_DIR/opt/coreutils/libexec/gnuman:$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# android studio
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export PATH="${PATH}:${ANDROID_HOME}/tools"
export PATH="${PATH}:${ANDROID_HOME}/platform-tools"

# go
export GOPATH="$HOME/Workspace"
export PATH="$PATH:$GOPATH/bin"

# keybase
export GPG_TTY=$(tty)

# rust
export PATH="$PATH:$HOME/.cargo/bin"

# Sourced here to make it available in login shells
source '/usr/local/opt/z/etc/profile.d/z.sh'
