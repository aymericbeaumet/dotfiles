# Load Homeshick
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
fpath=($HOME/.homesick/repos/homeshick/completions $fpath)
if which homeshick > /dev/null ; then homeshick --quiet refresh ; fi

# Load Docker
if which boot2docker > /dev/null ; then $(boot2docker shellinit 2> /dev/null) ; fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
if which brew > /dev/null ; then source "$(brew --prefix nvm)/nvm.sh" ; fi

# Load rbenv
if which rbenv > /dev/null ; then eval "$(rbenv init -)" ; fi

# Load Tmuxifier
export TMUXIFIER_LAYOUT_PATH="$HOME/.tmux/layouts"
if [ "$TERM_PROGRAM" = 'iTerm.app' ] ; then
  export TMUXIFIER_TMUX_ITERM_ATTACH='-CC'
fi
if which tmuxifier > /dev/null ; then eval "$(tmuxifier init -)" ; fi
