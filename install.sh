#!/bin/zsh

##
#git
##
rm -f ~/.gitconfig
if which git &> /dev/null ; then
  ln -sf `pwd`/git/gitconfig ~/.gitconfig || (echo '-> git ko!' && exit 1)
  echo '-> git ok!'
fi

##
#tmux
##
rm -f ~/.tmux
rm -f ~/.tmux.conf
if which tmux &> /dev/null ; then
  ln -sf `pwd`/tmux/tmux ~/.tmux || (echo '-> tmux ko!' && exit 1)
  ln -sf `pwd`/tmux/tmux.conf ~/.tmux.conf || (echo '-> tmux ko!' && exit 1)
  echo '-> tmux ok!'
fi

##
#vim
##
rm -f ~/.vim
rm -f ~/.vimrc
if which vi &> /dev/null || which vim &> /dev/null ; then
  ln -sf `pwd`/vim/vim ~/.vim || (echo '-> vi(m) ko!' && exit 1)
  ln -sf `pwd`/vim/vimrc ~/.vimrc || (echo '-> vi(m) ko!' && exit 1)
  echo '-> vi(m) ok!'
fi

##
#zsh
##
rm -f ~/.zshrc
if which zsh &> /dev/null ; then
  echo '(Change your login shell to zsh)' && chsh -s `which zsh` || (echo '-> zsh ko!' && exit 1)
  ln -sf `pwd`/zsh/zshrc ~/.zshrc || (echo '-> zsh ko!' && exit 1)
  echo '-> zsh ok!'
fi

exit 0
