# Load Homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fpath=($HOME/.homesick/repos/homeshick/completions $fpath)
homeshick --quiet refresh

# Load NVM
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

# Load rbenv
eval "$(rbenv init -)"

# Load Tmuxifier
export TMUXIFIER_LAYOUT_PATH="$HOME/.tmux/layouts"
if [ "$TERM_PROGRAM" = 'iTerm.app' ] ; then
  export TMUXIFIER_TMUX_ITERM_ATTACH='-CC'
fi
eval "$(tmuxifier init -)"
