# Make sure brew is in the path
which brew &>/dev/null || export PATH="/usr/local/bin:$HOME/.linuxbrew/bin:$PATH"

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
