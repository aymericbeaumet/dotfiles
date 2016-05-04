# Author: Aymeric Beaumet <aymeric@beaumet.me>
# Github: @aymericbeaumet/dotfiles

# zsh
fpath=("$HOME/.zsh/completion" $fpath)

# brew
local brew_dir="$HOME/.brew"
export PATH="$brew_dir/bin:$PATH"
export MANPATH="$brew_dir/share/man:$MANPATH"
export INFOPATH="$brew_dir/share/info:$INFOPATH"

# homeshick
local homeshick_dir="$HOME/.homesick/repos/homeshick"
fpath=("$homeshick_dir/completions" $fpath)
source "$homeshick_dir/homeshick.sh"
source "$(brew --prefix)/etc/profile.d/z.sh"

# node
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
mkdir -p "$GOPATH"
