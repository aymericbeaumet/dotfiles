# Load Homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fpath=($HOME/.homesick/repos/homeshick/completions $fpath)
homeshick --quiet refresh

# Load NVM
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
