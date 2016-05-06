# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

# brew
local brew_dir="$HOME/.brew"
export PATH="$brew_dir/bin:$PATH"
export MANPATH="$brew_dir/share/man:$MANPATH"
export INFOPATH="$brew_dir/share/info:$INFOPATH"

# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
mkdir -p "$GOPATH"

# homeshick
local homeshick_dir="$HOME/.homesick/repos/homeshick"
fpath=("$homeshick_dir/completions" $fpath)
source "$homeshick_dir/homeshick.sh"

# node
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

# zsh
fpath=("$HOME/.zsh/completion" $fpath)
