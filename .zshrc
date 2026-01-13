# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# powerlevel10k instant prompt (must be near top, before any console output)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zinit plugin manager (auto-install if missing)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ -d "$ZINIT_HOME" ]] || git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# theme: powerlevel10k (load immediately for instant prompt)
zinit ice depth=1
zinit light romkatv/powerlevel10k
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# completions: add docker completions to fpath
fpath=("$HOME/.docker/completions" $fpath)

# plugins (turbo mode: deferred loading for faster startup)
zinit wait lucid for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  blockf \
    zsh-users/zsh-completions \
  atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  atload"compdef g=git" \
    OMZL::git.zsh \
  Aloxaf/fzf-tab

# fzf-git: git keybindings (ctrl-g ctrl-f for files, ctrl-g ctrl-b for branches, etc.)
zinit wait lucid for junegunn/fzf-git.sh

# zstyles
zstyle ':completion:*' menu select
zstyle ':completion:*' ignore-line true
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:default' menu 'select=0'
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-checkout:*' tag-order 'heads' 'remote-branch-names' '*'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept' 'ctrl-n:down' 'ctrl-p:up'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 20
zstyle ':fzf-tab:complete:g:argument-rest' fzf-preview 'git log --oneline --graph --color=always -n 20 $word 2>/dev/null || git diff --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always -n 20 $word'

# cd to git root (or stay in pwd if not in a repo)
...() { cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || return 1; }

# git wrapper: `g` runs `git st`, `g <args>` runs `git <args>`
g() { (( $# )) && command git "$@" || command git st; }

# zoxide interactive: `z` opens fzf, `z <query>` filters then jumps
z() {
  local dir
  dir=$(zoxide query --list | fzf ${@:+--filter="$*" --select-1 --exit-0}) && cd "$dir"
}

# environment
typeset -U path                    # deduplicate PATH
export EDITOR=nvim
export PAGER=less
export REPORTTIME=5                # show timing for commands >5s
export KEYTIMEOUT=1                # reduce key sequence delay
export ZLE_RPROMPT_INDENT=0        # fix right-prompt spacing
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# aliases: tools
alias ap=ansible-playbook
alias b=bat
alias tf=terraform
alias v=$EDITOR
alias vi=$EDITOR
alias vim=$EDITOR
alias w='watchexec --restart --clear --'

# aliases: eza (ls replacement)
alias ls='eza --group --group-directories-first --sort=Name'
alias l='ls -l'
alias la='l -a'
alias t='l --tree'
alias ta='la --tree'

# keybindings
bindkey -e
bindkey '^[[Z' reverse-menu-complete  # shift-tab: reverse completion
autoload -U select-word-style && select-word-style bash

# options: directories
setopt AUTO_CD AUTO_PUSHD CHASE_DOTS CHASE_LINKS PUSHD_IGNORE_DUPS PUSHD_TO_HOME

# options: completion
setopt ALWAYS_TO_END AUTO_LIST AUTO_MENU AUTO_PARAM_KEYS AUTO_PARAM_SLASH
setopt AUTO_REMOVE_SLASH LIST_AMBIGUOUS LIST_PACKED LIST_TYPES
unsetopt nomatch
unsetopt COMPLETE_IN_WORD

# options: globbing
setopt BAD_PATTERN GLOB GLOBDOTS

# options: history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS HIST_NO_FUNCTIONS HIST_NO_STORE
setopt HIST_REDUCE_BLANKS HIST_SAVE_BY_COPY HIST_SAVE_NO_DUPS SHARE_HISTORY
unsetopt APPEND_HISTORY INC_APPEND_HISTORY

# options: input/output
setopt INTERACTIVE_COMMENTS RC_QUOTES
unsetopt FLOW_CONTROL

# restore cursor shape before prompt
autoload -Uz add-zsh-hook
_reset_cursor() { echo -ne '\e[5 q'; }
add-zsh-hook precmd _reset_cursor

# edit command line in $EDITOR with ^X^E
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line

# fzf: shell integration
source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/completion.zsh" 2>/dev/null
source "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell/key-bindings.zsh" 2>/dev/null
export FZF_DEFAULT_OPTS="
  --ansi --border --height=40% --layout=reverse --inline-info
  --bind tab:accept,ctrl-n:down,ctrl-p:up
  --bind ctrl-y:preview-up,ctrl-e:preview-down,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
"
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d --strip-cwd-prefix"

# zoxide: smart cd (we define custom `z` function above)
eval "$(zoxide init zsh --hook=pwd --no-cmd)"
