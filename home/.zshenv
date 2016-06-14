# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

# homebrew
export BREW_DIR="$HOME/.homebrew"
export PATH="$BREW_DIR/bin:$PATH"
export MANPATH="$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# cabal (haskell)
export PATH="$HOME/.cabal/bin:$PATH"

# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# node
export NVM_DIR="$HOME/.nvm"
which brew &>/dev/null && [ -r "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"

# zsh
fpath=("$HOME/.zsh/completion" $fpath)

# z
which brew &>/dev/null && [ -r "$(brew --prefix z)/etc/profile.d/z.sh" ] && source "$(brew --prefix z)/etc/profile.d/z.sh"
