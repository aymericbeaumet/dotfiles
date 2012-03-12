#!/bin/sh

##
#git
##
if which git &>/dev/null ; then
  rm -f ~/.gitconfig
  ln -sf `pwd`/git/gitconfig ~/.gitconfig
  echo '-> git ok!'
fi

##
#tmux
##
if which tmux &>/dev/null ; then
  rm -f ~/.tmux
  ln -sf `pwd`/tmux/tmux ~/.tmux
  rm -f ~/.tmux.conf
  ln -sf `pwd`/tmux/tmux.conf ~/.tmux.conf
  echo '-> tmux ok!'
fi

##
#vim
##
if which vim &>/dev/null ; then
  rm -rf ~/.vim
  ln -sf `pwd`/vim/vim ~/.vim
  rm -f ~/.vimrc
  ln -sf `pwd`/vim/vimrc ~/.vimrc
  echo '-> vim ok!'
fi

##
#zsh
##
if which zsh &>/dev/null ; then
  if which chsh &>/dev/null ; then
    chsh -s `which zsh | head -1` || exit 1
  fi
  rm -f ~/.zshrc
  ln -sf `pwd`/zsh/zshrc ~/.zshrc
  echo '-> zsh ok!'
fi

##
#anonymous pro font
##
if [ "$(uname -s)" = 'Linux' ] ; then
  if ! [ -d ~/.fonts ] ; then
    mkdir ~/.fonts
  fi
  cp -r ./anonymous_pro/*.ttf ~/.fonts/
  echo '-> anonymous pro font ok!'
fi

##
#ssh scripts
##
for link in `pwd`/ssh/* ; do
  ln -sf "$link" ~/"$(basename "$link")"
done
