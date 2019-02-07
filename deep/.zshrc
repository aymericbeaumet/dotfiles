# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	compinit
else
	compinit -C
fi

# commands {{{

  # du
  alias du='du -h'

  # git
  git()
  {
    if (( $# == 0 )) ; then
      command hub status -sb
    else
      command hub "$@"
    fi
  }
  alias g=git ; compdef g=git

  # grep
  alias grep='grep --color=auto'

  # less
  alias less='less -R'

  # ls
  eval "$(dircolors "$HOME/.dir_colors")" # https://github.com/seebi/dircolors-solarized
  alias ls='ls -pFH --color --group-directories-first'
  alias l='ls -hl' ; compdef l=ls
  alias ll='l' ; compdef ll=ls
  alias la='ll -A' ; compdef la=ls

  # tig
  alias t=tig

  # tmux
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # tree
  alias tree='tree -a -C --dirsfirst'

  # vim
  alias v='nvim'
  alias vi='nvim'
  alias vim='nvim'
  alias mvim='gnvim'
  alias gvim='gnvim'

# }}}

# settings {{{

  # open files
  export EDITOR=nvim
  export USE_EDITOR="$EDITOR"
  export VISUAL="$EDITOR"
  export REACT_EDITOR=code
  export VIEWER=open
  export PAGER=less

  # directory
  setopt AUTO_CD # change directory without cd (`..` goes up by one)

  # history (http://zsh.sourceforge.net/Doc/Release/Options.html)
  export HISTFILE="$HOME/.zsh/tmp/history"
  export SAVEHIST=10000
  export HISTSIZE=10000
  setopt APPEND_HISTORY       # do not overwrite history
  setopt INC_APPEND_HISTORY   # write after each command
  setopt SHARE_HISTORY        # share history between multiple shell sessions
  setopt EXTENDED_HISTORY     # more information in history (begin time, elapsed time, command)
  setopt HIST_IGNORE_DUPS
  setopt HIST_IGNORE_ALL_DUPS # avoid duplicate command lines in history
  setopt HIST_FIND_NO_DUPS    # do not display duplicate in search
  setopt HIST_REDUCE_BLANKS   # remove superfluous blanks from history
  setopt HIST_IGNORE_SPACE    # do not store a command in history if it begins with a space
  setopt HIST_EXPIRE_DUPS_FIRST
  setopt HIST_SAVE_NO_DUPS

  # autocomplete
  setopt AUTO_REMOVE_SLASH  # autoremove slash when not needed
  setopt AUTO_PARAM_SLASH   # automatically append a slash after a directory
  unsetopt COMPLETE_IN_WORD # complete at the end of a word even if the cursor is not after the last character
  # Allow arrow navigation
  zstyle ':completion:*' menu select
  # Don't complete stuff already on the line
  zstyle ':completion:*' ignore-line true
  # Don't complete directory we are already in
  zstyle ':completion:*' ignore-parents parent pwd
  # More complete output (not always)
  zstyle ':completion:*' verbose yes
  # Fix group name display
  zstyle ':completion:*' group-name ''
  # Case insensitive completion
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  # Ignore completion functions
  zstyle ':completion:*:functions' ignored-patterns '_*'
  # Explicitly write the type of what the autocomplete has found / was looking for
  zstyle ':completion:*:descriptions' format '%B%d%b'
  zstyle ':completion:*:warnings' format 'No matches for: %d'
  # Don't prompt for a huge list, page it!
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  zstyle ':completion:*:default' menu 'select=0'
  # Separate man page sections
  zstyle ':completion:*:manuals' separate-sections true
  # Ignore compiled files on vim completion
  zstyle ':completion:*:*:(v|vi|vim|mvim|nvim|gnvim|ghc|ghci|runhaskell):*:*files' ignored-patterns '*.(a|dylib|so|o|hi)'
  # allow shift-TAB to backward complete
  bindkey '^[[Z' reverse-menu-complete

  # disable flow control (^S / ^Q)
  stty stop undef
  stty start undef

  # bring the latest background app to foreground with ^Z
  on_ctrl_z() {
    if [[ -n "$(jobs)" ]] ; then
      fg
   fi
  }
  zle -N on_ctrl_z ; bindkey '^Z' on_ctrl_z

  # set window title to be the current directory
  precmd() {
    if [ -n "$ITERM_SESSION_ID" ] ; then
      echo -ne "\e]1;${PWD##*/}\a"
    fi
  }

  # set cursor
  echo -ne "\e[6 q"

  # emacs style bindings
  bindkey -e
  autoload -U select-word-style && select-word-style bash

# }}}

# plugins {{{

ANTIBODY_BUNDLE_FILE="$HOME/.zsh/tmp/plugins.sh"

antibody_bundle()
{
  cat >"$ANTIBODY_BUNDLE_FILE" <<EOF
$(antibody bundle mafredri/zsh-async)
$(antibody bundle sindresorhus/pure)
  EMACS=__notempty__ # forbid pure to set the title bar
  PURE_PROMPT_SYMBOL='λ'

$(antibody bundle robbyrussell/oh-my-zsh path:plugins/colored-man-pages)

source /usr/local/opt/fzf/shell/key-bindings.zsh

$(antibody bundle zsh-users/zsh-autosuggestions)

# (must be the last plugin to be loaded)
$(antibody bundle zsh-users/zsh-syntax-highlighting)
EOF
}

antibody_refresh()
{
  rm -f "$ANTIBODY_BUNDLE_FILE"
  antibody_bundle
}

if [ ! -r "$ANTIBODY_BUNDLE_FILE" ]; then
  antibody_bundle
fi
source "$ANTIBODY_BUNDLE_FILE"
