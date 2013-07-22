# Prompt
###

# Git prompt
if [ -r ~/.zsh/bundle/zsh-git-prompt/zshrc.sh ] ; then
  source ~/.zsh/bundle/zsh-git-prompt/zshrc.sh

  # Set install directory
  export __GIT_PROMPT_DIR=~/.zsh/bundle/zsh-git-prompt

  # Change defaults values
  ZSH_THEME_GIT_PROMPT_PREFIX="("
  ZSH_THEME_GIT_PROMPT_SUFFIX=")"
  ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
  ZSH_THEME_GIT_PROMPT_BRANCH="${fg[yellow]}"
  ZSH_THEME_GIT_PROMPT_STAGED="${fg[green]}±"
  ZSH_THEME_GIT_PROMPT_CONFLICTS="${fg[orange]}☠"
  ZSH_THEME_GIT_PROMPT_CHANGED="${fg[red]}≠"
  ZSH_THEME_GIT_PROMPT_REMOTE=""
  ZSH_THEME_GIT_PROMPT_UNTRACKED="…"
  ZSH_THEME_GIT_PROMPT_CLEAN="${fg[green]}✓"
fi

# set content
function set_prompt()
{
  # left prompt
  if [ -n "$(jobs)" ] ; then
    PROMPT="[${fg_bold[green]}%j${reset_color}&:?${fg_bold[green]}%?${reset_color}] "
  else
    PROMPT="%(0?..[${fg_bold[green]}%j${reset_color}&:?${fg_bold[green]}%?${reset_color}] )"
  fi
  git_prompt="$(git_super_status)"
  PROMPT="${PROMPT}[${fg[cyan]}%25<...<%~%<<$reset_color]${git_prompt:+ $git_prompt} %(!.#.$) "

  # right prompt
  RPROMPT=''
  if [ -n "$SHLVL" ] && [ $SHLVL -gt 1 ] ; then
    RPROMPT="{^${fg[cyan]}${SHLVL}$reset_color}"
  fi
  if [ -n "$SSH_CLIENT" ] ; then
    RPROMPT="${RPROMPT:+$RPROMPT }[%n${fg[cyan]}@$reset_color%M]"
  fi
}
