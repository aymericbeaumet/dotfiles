fpath=(
  "$HOME/.zsh/completion"
  "$HOME/.homesick/repos/homeshick/completions"
  "${fpath[@]}"
)

source "$HOME/.homesick/repos/homeshick/homeshick.sh"

export NVM_DIR="$HOME/.nvm"
source "$(/usr/local/bin/brew --prefix nvm)/nvm.sh"

source "$(/usr/local/bin/brew --prefix)/etc/profile.d/z.sh"
