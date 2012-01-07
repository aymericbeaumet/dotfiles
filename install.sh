#!/bin/sh

##
#git
##
if which git &> /dev/null ; then
  rm -f ~/.gitconfig
  ln -sf `pwd`/git/gitconfig ~/.gitconfig || (echo '-> git ko!' && break)
  echo '-> git ok!'
else
  echo '-> git not found!'
fi

##
#tmux
##
if which tmux &> /dev/null ; then
  rm -f ~/.tmux
  ln -sf `pwd`/tmux/tmux ~/.tmux || (echo '-> tmux ko!' ; break)
  rm -f ~/.tmux.conf
  ln -sf `pwd`/tmux/tmux.conf ~/.tmux.conf || (echo '-> tmux ko!' ; break)
  echo '-> tmux ok!'
else
  echo '-> tmux not found!'
fi

##
#vim
##
if which vim &> /dev/null ; then
  rm -rf ~/.vim
  ln -sf `pwd`/vim/vim ~/.vim || (echo '-> vim ko!' ; break)
  rm -f ~/.vimrc
  ln -sf `pwd`/vim/vimrc ~/.vimrc || (echo '-> vim ko!' ; break)
  echo '-> vim ok!'
else
  echo '-> vim not found!'
fi

##
#zsh
##
if which zsh &> /dev/null ; then
  echo '(Change your login shell to zsh)' && chsh -s `which zsh` || (echo '-> zsh ko!' ; break)
  rm -f ~/.zshrc
  ln -sf `pwd`/zsh/zshrc ~/.zshrc || (echo '-> zsh ko!' ; break)
  echo '-> zsh ok!'
else
  echo '-> zsh not found!'
fi

##
#zsh
##
if which fluxbox &> /dev/null ; then
  rm -rf ~/.fluxbox
  ln -sf `pwd`/fluxbox ~/.fluxbox || (echo '-> fluxbox ko!' ; break)
  echo '-> fluxbox ok!'
else
  echo '-> fluxbox not found!'
fi
