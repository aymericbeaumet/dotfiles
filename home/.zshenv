# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

# brew
export PATH="$HOME/.brew/bin:$PATH"
export MANPATH="$HOME/.brew/share/man:$MANPATH"
export INFOPATH="$HOME/.brew/share/info:$INFOPATH"

# cabal (haskell)
export PATH="$HOME/.cabal/bin:$PATH"

# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# node
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

# zsh
fpath=("$HOME/.zsh/completion" $fpath)

# z
source "$(brew --prefix)/etc/profile.d/z.sh"
