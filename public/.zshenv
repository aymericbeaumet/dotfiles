# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

setopt noglobalrcs

# homebrew
export BREW_DIR='/usr/local'
export PATH="$BREW_DIR/opt/coreutils/libexec/gnubin:$BREW_DIR/bin:$PATH:/usr/sbin:/sbin"
export MANPATH="$BREW_DIR/opt/coreutils/libexec/gnuman:$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# Sourced here to make it available in login shells
source '/usr/local/opt/z/etc/profile.d/z.sh'
