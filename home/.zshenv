# Make sure brew is in the path
export PATH="$HOME/.linuxbrew/bin:/usr/local/bin:$PATH"
export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

# Setup zsh completion
fpath=(
  "$HOME/.zsh/completion"
  "$HOME/.homesick/repos/homeshick/completions"
  "${fpath[@]}"
)

# Setup homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"

# Setup nvm
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

# Setup z
source "$(brew --prefix)/etc/profile.d/z.sh"
