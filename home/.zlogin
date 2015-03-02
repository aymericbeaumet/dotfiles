# Load Homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fpath=($HOME/.homesick/repos/homeshick/completions $fpath)
if which homeshick > /dev/null ; then homeshick --quiet refresh ; fi

# Load Boot2Docker
if which boot2docker > /dev/null ; then $(boot2docker shellinit 2> /dev/null) ; fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
if which brew > /dev/null ; then source "$(brew --prefix nvm)/nvm.sh" ; fi
