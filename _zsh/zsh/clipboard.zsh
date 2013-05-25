# Easy clipboard manage:
#  - 0 parameter -> print its content
#  - 1+ parameter(s) or data on standard input -> store content
function clipboard()
{
  content=''

  # if parameters, use it
  if [ $# -gt 0 ] ; then
    for i in $@ ; do content="$content$(<$i)" done
    _update_clipboard "$content"
    return
  fi

  # if not tty, read standard input
  if ! [ -t 0 ] ; then
    while read line ; do content="$content$line" done
  fi

  # if data on standard input, use it
  [ -n "$content" ] && (_update_clipboard "$content" ; return)

  # else print clipboard
  _print_clipboard
}

function _print_clipboard()
{
  if is_macosx ; then
    pbpaste
  fi
}

function _update_clipboard()
{
  if is_macosx ; then
    pbcopy <<< "$1"
  fi
}
