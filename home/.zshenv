BREW_DIR="$HOME/.brew"
HOMESHICK_DIR="$HOME/.homesick/repos/homeshick"

# make sure brew is in the path
export PATH="$BREW_DIR/bin:$PATH"
export MANPATH="$BREW_DIR/share/man:$MANPATH"
export INFOPATH="$BREW_DIR/share/info:$INFOPATH"

# setup zsh completion
fpath=(
  "$HOME/.zsh/completion"
  "$HOMESHICK_DIR/completions"
  "${fpath[@]}"
)

# setup third-parties
source "$HOMESHICK_DIR/homeshick.sh"
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"
source "$(brew --prefix)/etc/profile.d/z.sh"

# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
