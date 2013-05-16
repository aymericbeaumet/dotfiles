# colors
RED_COLOR=$'%{\033[31m%}'
RESET_DISPLAY=$'%{\033[0m%}'

# content
function set_prompt()
{
  # left prompt
  PROMPT="[${RED_COLOR}%j${RESET_DISPLAY}&:?${RED_COLOR}%?${RESET_DISPLAY}]"
  PROMPT="$PROMPT [$RED_COLOR%20<...<%~%<<$RESET_DISPLAY] %(!.#.$) "

  # right prompt
  RPROMPT="{^${RED_COLOR}${SHLVL}$RESET_DISPLAY}"
  RPROMPT=" [%n$RED_COLOR@$RESET_DISPLAY%M]"
}
