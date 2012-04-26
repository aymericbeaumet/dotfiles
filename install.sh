#!/bin/sh

##
#config
##
GIT_CONF_FILE=~/.gitconfig
TMUX_CONF_FILE=~/.tmux.conf
TMUX_CONF_DIR=~/.tmux
VIM_CONF_FILE=~/.vimrc
VIM_CONF_DIR=~/.vim
ZSH_CONF_FILE=~/.zshrc
ZSH_CONF_DIR=~/.zsh

##
#git
##
if which git &>/dev/null ; then
  rm -rf "$GIT_CONF_FILE"
  ln -sf "$(pwd)/_git/conf_file" "$GIT_CONF_FILE"
  echo '-> git ok!'
fi

##
#tmux
##
if which tmux &>/dev/null ; then
  rm -rf "$TMUX_CONF_FILE"
  ln -sf "$(pwd)/_tmux/conf_file" "$TMUX_CONF_FILE"
  rm -rf "$TMUX_CONF_DIR"
  ln -sf "$(pwd)/_tmux/data" "$TMUX_CONF_DIR"
  echo '-> tmux ok!'
fi

##
#vim
##
if which vim &>/dev/null ; then
  rm -rf "$VIM_CONF_FILE"
  ln -sf "$(pwd)/_vim/conf_file" "$VIM_CONF_FILE"
  rm -rf "$VIM_CONF_DIR"
  ln -sf "$(pwd)/_vim/data" "$VIM_CONF_DIR"
  rm -rf "$(pwd)/_vim/data/autoload/pathogen.vim"
  ln -sf "$(pwd)/_vim/pathogen/autoload/pathogen.vim" "$(pwd)/_vim/data/autoload/pathogen.vim"
  echo '-> vim ok!'
fi

##
#zsh
##
if which zsh &>/dev/null ; then
  if which chsh &>/dev/null ; then
    chsh -s $(which zsh | head -1)
  fi
  rm -rf "$ZSH_CONF_FILE"
  ln -sf "$(pwd)/_zsh/conf_file" "$ZSH_CONF_FILE"
  rm -rf "$ZSH_CONF_DIR"
  ln -sf "$(pwd)/_zsh/data" "$ZSH_CONF_DIR"
  echo '-> zsh ok!'
fi

##
#anonymous pro font
##
if [ "$(uname -s)" = 'Linux' ] ; then
  if ! [ -d ~/.fonts ] ; then
    mkdir ~/.fonts
  fi
  cp -r ./__anonymous_pro_font/*.ttf ~/.fonts/
  echo '-> anonymous pro font ok!'
fi

##
#ssh scripts
##
for link in "$(pwd)/__ssh_fast_connect_scripts/"* ; do
  ln -sf "$link" ~/"$(basename "$link")"
done
echo '-> ssh scripts ok!'
