# System
###

# return 0 if $1 exists (as an alias or executable file in $PATH)
function cmd_exists()
{
  return $([ $# -ne 0 ] && which $1 &>/dev/null);
}

# write 'unknown', only defined if uname(1) is not in $PATH
if ! cmd_exists uname ; then
  function uname()
  {
    echo unknown
  }
fi

# return 0 if the os is linux
function is_linux()
{
  return $([ `uname -s` = Linux ]);
}

# return 0 if the os is macosx
function is_macosx()
{
  return $([ `uname -s` = Darwin ]);
}

# return 0 if the os is bsd
function is_bsd()
{
  return $([[ `uname -s` =~ .*bsd.* ]]);
}
