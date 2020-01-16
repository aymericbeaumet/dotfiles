# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit
if [ -n "${ZDOTDIR}/.zcompdump(#qN.mh+24)" ]; then
  compinit
else
  compinit -C
fi

# commands {{{

  # fzf - cd
  fcd() {
    local candidates="$(fd --color=never --type directory . "${1:-$(pwd)}")"
    if [ -z "$candidates" ]; then
      return 0
    fi
    builtin cd $(echo "$candidates" | fzf)
  }

  # asdf
  asdf() {
    if ! [ -x "$(command -v asdf)" ]; then
      . $(brew --prefix asdf)/asdf.sh
    fi
    command asdf "$@"
  }

  # bat
  alias -g B="| bat"
  alias -g J="| bat -l json"
  alias -g Y="| bat -l yaml"

  # cat
  alias cat='bat --plain --paging=never'

  # docker
  docker() {
    command docker "$@"
  }
  alias d=docker

  # du
  alias du='du -h'

  # fzf
  export FZF_DEFAULT_OPTS='--ansi --border --inline-info --height 40% --layout=reverse'

  # git
  git() {
    if (( $# == 0 )); then
      command hub status -sb
    else
      command hub "$@"
    fi
  }
  alias g=git

  # grep
  alias -g G="|& grep -i"
  export GREP_COLOR=auto

  # kubectl, kubens kubectx
  kubectl() {
    if (( $# == 0 )); then
      command kubectl cluster-info
    else
      case "$1" in
        # kubectx
        ctx|context|contexts) shift; command kubectx "$@";;
        # kubens
        ns|namespace|namespaces) shift; command kubens "$@";;
        # kubectl
        *) command kubectl "$@";;
      esac
    fi
  }
  alias k=kubectl

  # less
  alias -g L="|& less"
  export LESS=R
  export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
  export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
  export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
  export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
  export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
  export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
  export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
  export PAGER='less'

  # ls
  alias ls='ls -pFH --color --group-directories-first'
  alias ll='ls -hl' ; compdef ll=ls
  alias la='ll -A' ; compdef la=ls

  # mkdir
  alias mkdir='mkdir -p'

  # nvim
  alias -s {json,yml,yaml,toml}=nvim

  # pbcopy, pbpaste
  alias -g C="| pbcopy"
  alias -g P="| pbpaste"

  # pup
  alias pup='pup --color'

  # ranger
  alias r='ranger'

  # terraform
  terraform() {
    if (( $# == 0 )); then
      command terraform workspace show
    else
      command terraform "$@"
    fi
  }
  alias tf=terraform

  # tmux
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8

  # tree
  alias tree='tree -a -C --dirsfirst'

  # tmux
  t() {
    [ -n "$TMUX" ] && local action='switch' || local action='attach'
    # Try to attach/switch to the session if a name is provided (create if needed)
    if [ -n "$1" ]; then
      tmux "$action" -t "$1" || {
        tmux new-session -d -s "$1"
        tmux "$action" -t "$1"
      }
      return $?
    fi
    # Gather the candidates sessions, then attach/switch to the selected one
    local candidates="$(tmux_list_sessions_by_most_recently_attached_excluding_current_one)"
    if [ -z "$candidates" ]; then
      echo "No session to $action to."
      return 0
    fi
    local session="$(echo "$candidates" | fzf)"
    tmux "$action" -t "$session"
    return $?
  }

  _t() {
    _arguments -C \
      "1: :($(tmux_list_sessions_by_most_recently_attached_excluding_current_one))" \
      "*::arg:->args"
  }

  compdef _t t

  # z

  unalias z &> /dev/null
  z() {
    [ $# -gt 0 ] && _z "$*" && return
    cd "$(_z -l 2>&1 | fzf --nth 2.. +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
  }

# }}}

# helpers {{{

docker_wipe() {
  docker stop $(docker ps -aq)
  docker system prune --all --volumes --force
}

tmux_list_sessions_by_most_recently_attached_excluding_current_one() {
  local exclude="$([ -n "$TMUX" ] && tmux display-message -p '#{session_name}')"
  tmux ls -F "#{session_last_attached} #{session_name}" | egrep -v "^\d+ ${exclude}$" | sort -rn | cut -d' ' -f2
}

# }}}

# settings {{{

  # open files
  export EDITOR=nvim
  export USE_EDITOR="$EDITOR"
  export VISUAL="$EDITOR"
  export REACT_EDITOR=code
  export VIEWER=open

  # directory
  setopt AUTO_CD           # change directory without cd (`..` goes up by one)
  setopt AUTO_PUSHD        # build a stack of cd history (cd -1, cd -2, etc)
  setopt PUSHD_IGNORE_DUPS # ignore dups when building the stack

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

  # disable flow control (give me ^S/^Q back!)
  stty stop undef
  stty start undef

  # bash-like word selection
  autoload -U select-word-style && select-word-style bash

  # emacs bindings
  bindkey -e

  # bring the latest background app to foreground with ^Z
  on_ctrl_z() {
    if [ -n "$(jobs)" ]; then
      fg
   fi
  }
  zle -N on_ctrl_z; bindkey '^Z' on_ctrl_z

  # make sure the cursor is a line
  zle-line-init()
  {
    if [[ -n "$TMUX" ]]; then
        print -n -- '\033[6 q'
    else
        print -n -- "\E]50;CursorShape=1\C-G"
    fi
  }
  zle -N zle-line-init

# }}}

# secrets {{{

source "$HOME/.secrets/.zshrc"

# }}}

# plugins {{{

ANTIBODY_BUNDLE_FILE="$HOME/.zsh/tmp/plugins.sh"

POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir kubecontext vcs newline background_jobs dir_writable status)
POWERLEVEL9K_DISABLE_RPROMPT=true
POWERLEVEL9K_STATUS_CROSS=true

antibody_bundle()
{
  cat >"$ANTIBODY_BUNDLE_FILE" <<EOF
source $(brew --prefix fzf)/shell/key-bindings.zsh

$(antibody bundle romkatv/powerlevel10k)

$(antibody bundle zsh-users/zsh-autosuggestions)

# (must be the last plugin to be loaded)
$(antibody bundle zsh-users/zsh-syntax-highlighting)
EOF
}

if [ ! -r "$ANTIBODY_BUNDLE_FILE" ]; then
  antibody_bundle
fi
source "$ANTIBODY_BUNDLE_FILE"
