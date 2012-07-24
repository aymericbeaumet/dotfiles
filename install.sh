#!/bin/sh

##
#config
##

source './config.cfg'
current_path="$(pwd)"
current_user="$(whoami)"

if [ -z "$current_path" ] ; then current_path="/tmp" ; fi
if [ -z "$current_user" ] ; then current_user="unknown" ; fi

##
#functions
##

function cmd_exists()
{
  if [ "$#" -eq '0' ] || ! which "$1" &>/dev/null ; then
    return 1
  fi
  return 0
}

function do_backup()
{
  if [ -n "$1" ] && [ -f "$1" ] ; then
    mv -f "$1" "$1.$BACKUP_EXT"
  fi
}

##
#warning
##

echo 'This script will install the configuration files for the following programs:'
echo '  - git'
echo '  - tmux'
echo '  - zsh'
echo 'And also the font Anonymous Pro.'
echo 'Do you wish to continue [Y/n]?'
read answer
answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
if [ "$answer" = 'n' ] || [ "$answer" = 'no' ] ; then exit 0 ; fi

##
#git
##
if cmd_exists git ; then
  do_backup "$GIT_CONF_FILE"
  ln -sf "$current_path/git/conf_file" "$GIT_CONF_FILE"
  echo '-> git ok!'

  git submodule update --init
  echo '-> submodules ok!'
fi

##
#tmux
##
if cmd_exists tmux ; then
  do_backup "$TMUX_CONF_FILE"
  ln -sf "$current_path/tmux/conf_file" "$TMUX_CONF_FILE"
  do_backup "$TMUX_CONF_DIR"
  ln -sf "$current_path/tmux/data" "$TMUX_CONF_DIR"
  echo '-> tmux ok!'
fi

##
#vim
##
if cmd_exists vim ; then
  do_backup "$VIM_CONF_FILE"
  ln -sf "$current_path/vim/conf_file" "$VIM_CONF_FILE"
  do_backup "$VIM_CONF_DIR"
  ln -sf "$current_path/vim/data" "$VIM_CONF_DIR"
  rm -rf "$current_path/vim/data/autoload/pathogen.vim"
  ln -sf "$current_path/vim/pathogen/autoload/pathogen.vim" "$current_path/vim/data/autoload/pathogen.vim"
  echo '-> vim ok!'
fi

##
#zsh
##
if cmd_exists zsh ; then
  if cmd_exists chsh ; then
    echo -n 'Do you want to set your default shell to zsh [y/N]? '
    read answer
    answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
    if [ "$answer" = 'y' ] || [ "$answer" = 'yes' ] ; then
      echo "$current_user, please enter your password to proceed:"
      chsh -s $(which zsh | head -1)
    fi
  fi
  do_backup "$ZSH_CONF_FILE"
  ln -sf "$current_path/zsh/conf_file" "$ZSH_CONF_FILE"
  do_backup "$ZSH_CONF_DIR"
  ln -sf "$current_path/zsh/data" "$ZSH_CONF_DIR"
  echo '-> zsh ok!'
fi

##
#anonymous pro font
##
if ! [ -d ~/.fonts ] ; then
  mkdir ~/.fonts
fi
cp -r ./anonymous_pro_font/*.ttf ~/.fonts/
echo '-> fonts ok!'

exit 0
