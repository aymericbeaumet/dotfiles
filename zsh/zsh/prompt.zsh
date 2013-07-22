# Prompt
###

autoload -U colors && colors

# Preload colors specific colors
COLOR_RESET=$'%{\033[0m%}'
COLOR_BLUE=$'%{\033[38;05;75m%}'
COLOR_GREEN=$'%{\033[38;05;76m%}'
COLOR_LIGHT_GREEN=$'%{\033[38;05;46m%}'
COLOR_YELLOW=$'%{\033[38;05;220m%}'
COLOR_RED=$'%{\033[38;05;160m%}'
COLOR_ORANGE=$'%{\033[38;05;202m%}'
COLOR_VIOLET=$'%{\033[38;05;125m%}'

# Git prompt
if [ -r ~/.zsh/bundle/zsh-git-prompt/zshrc.sh ] ; then
  source ~/.zsh/bundle/zsh-git-prompt/zshrc.sh

  # Set install directory
  export __GIT_PROMPT_DIR=~/.zsh/bundle/zsh-git-prompt

  # Change defaults values
  ZSH_THEME_GIT_PROMPT_PREFIX="("
  ZSH_THEME_GIT_PROMPT_SUFFIX=")"
  ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
  ZSH_THEME_GIT_PROMPT_BRANCH="${COLOR_YELLOW}"
  ZSH_THEME_GIT_PROMPT_STAGED="${COLOR_GREEN}±"
  ZSH_THEME_GIT_PROMPT_CONFLICTS="${COLOR_ORANGE}×"
  ZSH_THEME_GIT_PROMPT_CHANGED="${COLOR_RED}≠"
  ZSH_THEME_GIT_PROMPT_REMOTE=""
  ZSH_THEME_GIT_PROMPT_UNTRACKED="…"
  ZSH_THEME_GIT_PROMPT_CLEAN="${COLOR_LIGHT_GREEN}✓"
fi

# set content
function set_prompt()
{
  # get git prompt
  git_prompt="$(git_super_status)"

  # left prompt
  PROMPT=''
  if [ -n "$(jobs)" ] ; then
    PROMPT="[$COLOR_BLUE%j$COLOR_RESET&:?$COLOR_BLUE%?$COLOR_RESET] "
  else
    PROMPT="%(0?..[$COLOR_BLUE%j$COLOR_RESET&:?$COLOR_BLUE%?$COLOR_RESET] )"
  fi
  PROMPT="${PROMPT}[$COLOR_BLUE%25<...<%~%<<$COLOR_RESET]${git_prompt:+ $git_prompt} %(!.#.$) "

  # right prompt
  RPROMPT=''
  if [ -n "$SHLVL" ] && [ $SHLVL -gt 1 ] ; then
    RPROMPT="${RPROMPT:+$RPROMPT }{^$COLOR_BLUE$SHLVL$COLOR_RESET}"
  fi
  if [ -n "$SSH_CLIENT" ] ; then
    RPROMPT="${RPROMPT:+$RPROMPT }[%n$COLOR_BLUE@$COLOR_RESET%M]"
  fi
}
