# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

autoload -Uz compinit && compinit # compdef

# commands {{{

  # du
  alias du='du -h'

  # git
  git_wrapper()
  {
    if (( $# == 0 )) ; then
      command git status -sb
    else
      command git "$@"
    fi
  }
  alias g='noglob git_wrapper' ; compdef g=git
  alias git='noglob git_wrapper'

  # grep
  alias grep='grep --color=auto'

  # less
  alias less='less -R'

  # ls
  eval "$(dircolors "$HOME/.dir_colors")" # https://github.com/seebi/dircolors-solarized
  alias ls="ls -pFH --color --group-directories-first"
  alias l='ls -hl' ; compdef l=ls
  alias ll='l' ; compdef ll=ls
  alias la='ll -A' ; compdef la=ls

  # tmux
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  tmux_wrapper()
  {
    if (( $# == 0 )) ; then
      command tmux new-session -A -s main
    else
      command tmux "$@"
    fi
  }
  alias t='noglob tmux_wrapper' ; compdef t=tmux
  alias tmux='noglob tmux_wrapper'
  if [[ -z "$TMUX" ]] ; then
    t
  fi

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

  # emacs style bindings
  bindkey -e
  autoload -U select-word-style && select-word-style bash

  # open files
  export EDITOR=nvim
  export USE_EDITOR="$EDITOR"
  export VISUAL="$EDITOR"
  export VIEWER=open
  export PAGER=less

  # directory
  setopt AUTO_CD # change directory without cd (`..` goes up by one)

  # history
  export HISTFILE="$HOME/.zsh/tmp/history"
  export SAVEHIST=10000
  export HISTSIZE=10000
  setopt APPEND_HISTORY       # do not overwrite history
  setopt INC_APPEND_HISTORY   # write after each command
  setopt SHARE_HISTORY        # share history between multiple shell sessions
  setopt EXTENDED_HISTORY     # more information in history (begin time, elapsed time, command)
  setopt HIST_IGNORE_DUPS     # avoid duplicate command lines in history
  setopt HIST_REDUCE_BLANKS   # remove superfluous blanks from history
  setopt HIST_IGNORE_SPACE    # do not store a command in history if it begins with a space
  setopt HIST_NO_STORE        # do not store the `history` command
  setopt HIST_NO_FUNCTIONS    # remove function definition from history

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

  # disable flow control (^S / ^Q)
  stty stop undef
  stty start undef

  # make sure to only send non-empty buffer with ^M or ^O
  on_ctrl_m_or_o() {
    if [[ -n "$BUFFER" ]] ; then
      zle accept-line
    fi
  }
  zle -N on_ctrl_m_or_o ; bindkey '^M' on_ctrl_m_or_o
  zle -N on_ctrl_m_or_o ; bindkey '^O' on_ctrl_m_or_o

  # bring the latest background app to foreground with ^Z
  on_ctrl_z() {
    if [[ -n "$(jobs)" ]] ; then
      fg
    fi
  }
  zle -N on_ctrl_z ; bindkey '^Z' on_ctrl_z

  # prompt
  setopt transient_rprompt

  # env
  if [[ -n "$TMUX" ]] ; then
    export TERM=screen-256color
  else
    export TERM=xterm-256color
  fi

# }}}

# plugins {{{

  export ZPLUG_HOME="$HOME/.zsh/bundle"
  source "$ZPLUG_HOME/zplug/init.zsh"

  zplug "$HOME/.zsh/tmp", from:local, use:promptline.sh

  zplug '/usr/local/opt/z/etc/profile.d', from:local, use:z.sh

  zplug '/usr/local/opt/fzf/shell', from:local, use:key-bindings.zsh
    export FZF_DEFAULT_COMMAND='fzf-tmux'
    export FZF_DEFAULT_OPTS='-d 30%'

  zplug 'zsh-users/zsh-syntax-highlighting', from:github, use:zsh-syntax-highlighting.plugin.zsh

  if ! zplug check ; then
    zplug install
  fi

  zplug load

# }}}
