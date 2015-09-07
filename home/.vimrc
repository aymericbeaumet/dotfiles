" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

" Skip initialization for vim-tiny or vim-small
if !1 | finish | endif

" Disable Vi compatibility
if &compatible | set nocompatible | endif

" Load and configure plugins
call plug#begin('~/.vim/bundle')
  Plug 'wombat256.vim'

  Plug 'Lokaltog/vim-easymotion'
  Plug 'SirVer/ultisnips'
  "Plug 'Valloric/YouCompleteMe', { 'do': './install.sh --clang-completer' }
  Plug 'airblade/vim-gitgutter'
  Plug 'airblade/vim-rooter'
  Plug 'bling/vim-airline'
  Plug 'editorconfig/editorconfig-vim'
  Plug 'jimsei/winresizer'

  Plug 'scrooloose/nerdcommenter'
  Plug 'scrooloose/syntastic'
  Plug 'tpope/vim-abolish'
  Plug 'tpope/vim-eunuch'

  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-speeddating'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-unimpaired'

  " Docker
  Plug 'ekalinin/Dockerfile.vim', { 'for': 'docker' }

  " Git
  Plug 'tpope/vim-git'

  " Javascript
  Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
  Plug 'jelera/vim-javascript-syntax', { 'for': 'javascript' }
  Plug 'marijnh/tern_for_vim', { 'for': 'javascript', 'do': 'npm install' }
  Plug 'myhere/vim-nodejs-complete', { 'for': 'javascript' }

   " JSON
  Plug 'elzr/vim-json', { 'for': 'json' }

  " Markdown
  Plug 'tpope/vim-markdown', { 'for': 'markdown' }
call plug#end()
