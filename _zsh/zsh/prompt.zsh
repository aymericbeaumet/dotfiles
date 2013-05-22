# colors
RED_COLOR=$'%{\033[31m%}'
RESET_DISPLAY=$'%{\033[0m%}'

# content
function set_prompt()
{
  # left prompt
  if [ -n "$(jobs)" ] ; then
    PROMPT="[${RED_COLOR}%j${RESET_DISPLAY}&:?${RED_COLOR}%?${RESET_DISPLAY}] "
  else
    PROMPT="%(0?..[${RED_COLOR}%j${RESET_DISPLAY}&:?${RED_COLOR}%?${RESET_DISPLAY}] )"
  fi
  PROMPT="${PROMPT}[$RED_COLOR%25<...<%~%<<$RESET_DISPLAY] %(!.#.$) "

  # right prompt
  RPROMPT=''
  if [ -n "$SHLVL" ] && [ $SHLVL -gt 1 ] ; then
    RPROMPT="{^${RED_COLOR}${SHLVL}$RESET_DISPLAY}"
  fi
  if [ -n "$SSH_CLIENT" ] ; then
    RPROMPT="${RPROMPT:+$RPROMPT }[%n$RED_COLOR@$RESET_DISPLAY%M]"
  fi
}
