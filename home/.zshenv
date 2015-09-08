# https://github.com/creationix/nvm/issues/539#issuecomment-110643090
lazy_source () {
  eval "\"$1\" () { [ -r \"$2\" ] && source \"$2\" && \"$1\" \"\$@\" }"
}

# nvm
export NVM_DIR="$HOME/.nvm"
lazy_source nvm "$(brew --prefix nvm)/nvm.sh"
