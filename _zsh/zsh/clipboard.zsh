# Clipboard
###

# * The function concatenates the content of all the files passed as parameters
#   (in their apparitions order) and then store it in the clipboard.
# * If no parameter is given, try to read on standard input.
# * If something is found on standard input, store it in the clipboard.
# * If nothing is found on standard input, print the clipboard content.

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
  [ -n "$content" ] && { _update_clipboard "$content" ; return }

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
