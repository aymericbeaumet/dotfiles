# Environment
###

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
export EDITOR=`which vim 2>/dev/null || which vi 2>/dev/null \
  || echo $EDITOR`
export USE_EDITOR=$EDITOR
export VISUAL=$EDITOR
export VIEWER=`which eog 2>/dev/null || echo $VIEWER`
export PAGER=`which less 2>/dev/null || which more 2>/dev/null \
  || which cat 2>/dev/null || echo $PAGER`
export SHELL=`which zsh 2>/dev/null || which bash 2>/dev/null || echo $SHELL`
