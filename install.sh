##
#git
ln -sf `pwd`/git/gitconfig ~/.gitconfig

##
#tmux
ln -sf `pwd`/tmux/tmux.conf ~/.tmux.conf
ln -sf `pwd`/tmux/scripts/lmenu.sh ~/.tmux.lmenu.sh
ln -sf `pwd`/tmux/scripts/rmenu.sh ~/.tmux.rmenu.sh

##
#vim
rm -f ~/.vim && ln -sf `pwd`/vim/vim/ ~/.vim
ln -sf `pwd`/vim/vimrc ~/.vimrc

##
#zsh
ln -sf `pwd`/zsh/zshrc ~/.zshrc
