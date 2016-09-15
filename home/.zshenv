# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

setopt noglobalrcs

# homebrew
export BREW_DIR='/usr/local'
export PATH="$BREW_DIR/opt/coreutils/libexec/gnubin:$BREW_DIR/bin:$PATH"
export MANPATH="$BREW_DIR/opt/coreutils/libexec/gnuman:$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# zsh
fpath=("$HOME/.zsh/completion" $fpath)

# z
source "$(brew --prefix z)/etc/profile.d/z.sh"
