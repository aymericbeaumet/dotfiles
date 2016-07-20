# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

setopt noglobalrcs

# homebrew
export BREW_DIR="/usr/local"
export PATH="$BREW_DIR/opt/coreutils/libexec/gnubin:$BREW_DIR/bin:$PATH"
export MANPATH="$BREW_DIR/opt/coreutils/libexec/gnuman:$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# npm
which npm &>/dev/null && source <(npm completion)

# zsh
fpath=("$HOME/.zsh/completion" $fpath)

# z
[ -r "$(brew --prefix z 2>/dev/null)/etc/profile.d/z.sh" ] && source "$(brew --prefix z)/etc/profile.d/z.sh"
