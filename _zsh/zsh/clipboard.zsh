# Easy clipboard manage:
#  - 0 parameter -> print its content
#  - 1+ parameter(s) or data on standard input -> store content
function clipboard()
{
  content=''
  if [ -t 0 ] ; then
    while read -t 0 line ; do
      content="$content$line"
    done
  fi

  echo $content

  if [ $# -gt 0 ] ; then
    _update_clipboard "$@"
  elif [ -n "$content" ] ; then
    _update_clipboard "$content"
  else
    _print_clipboard
  fi
}

function _print_clipboard()
{
  if is_macosx ; then
    pbpaste
  fi
}

function _update_clipboard()
{
  echo "Update keyboard with '$1'"
}
