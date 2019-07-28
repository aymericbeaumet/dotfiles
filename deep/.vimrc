" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
" Github: @aymericbeaumet/dotfiles

" init {{{

  if !1 | finish | endif " Skip initialization for vim-tiny or vim-small

  if exists('&compatible') | set nocompatible | endif " 21st century

  syntax enable
  filetype plugin indent on
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins'  }
      inoremap <expr> <TAB> pumvisible() ? "\<CR>" : "\<TAB>"
      let g:deoplete#enable_at_startup = 1
      let g:deoplete#auto_completion_start_length = 1
      set completeopt-=preview
      imap <silent><expr> <C-Space> deoplete#manual_complete()

    Plug 'w0rp/ale'
      let g:ale_sign_error = '⤫'
      let g:ale_sign_warning = '⚠'

    Plug 'honza/dockerfile.vim'

    Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
      let g:go_fmt_command = "goimports"
      let g:go_fmt_fail_silently = 1 " ale is taking care of errors
      let g:go_highlight_build_constraints = 1
      let g:go_highlight_extra_types = 1
      let g:go_highlight_fields = 1
      let g:go_highlight_functions = 1
      let g:go_highlight_methods = 1
      let g:go_highlight_operators = 1
      let g:go_highlight_structs = 1
      let g:go_highlight_types = 1
      let g:go_auto_sameids = 1
      let g:go_auto_type_info = 1
      let g:go_addtags_transform = "snakecase"

    Plug 'elzr/vim-json'

    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
      autocmd FileType markdown nmap <buffer> <leader>p <Plug>MarkdownPreview

    Plug 'rust-lang/rust.vim'

    Plug 'ntpeters/vim-better-whitespace'
      let g:better_whitespace_enabled=1
      let g:strip_whitespace_on_save=1
    Plug 'editorconfig/editorconfig-vim'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-rhubarb'
    Plug 'scrooloose/nerdtree'
      nmap <silent> <leader>e :NERDTreeToggle<CR>
      let g:NERDTreeMinimalUI = 1
      " close vim if nerdtree if the latest instance
      autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    Plug 'scrooloose/nerdcommenter'
      let g:NERDCommentWholeLinesInVMode = 1
      let g:NERDMenuMode = 0
      let g:NERDSpaceDelims = 1

    Plug 'cohama/lexima.vim'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-eunuch'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'
      let g:surround_indent = 1 " reindent with `=` after surrounding
    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_verbose = 0
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_keys = 'tnseriaodhplfuwyq;gjvmc,x.z/bk' " colemak
    Plug 'terryma/vim-multiple-cursors'
    Plug '/usr/local/opt/fzf'
    Plug 'junegunn/fzf.vim'
      nmap <silent> <leader>b :Buffers<CR>
      nmap <silent> <leader>c :Commits<CR>
      nmap <silent> <leader>f :Files<CR>
    Plug 'farmergreg/vim-lastplace'

    Plug 'vim-airline/vim-airline'
      set noshowmode " hide the duplicate mode in bottom status bar
      let g:airline_theme = 'nord'
      let g:airline_powerline_fonts = 1
      let g:airline#extensions#ale#enabled = 1
    Plug 'ryanoasis/vim-devicons'
    Plug 'arcticicestudio/nord-vim'
    Plug 'junegunn/goyo.vim'

  call plug#end()

  call deoplete#custom#option('omni_patterns', { 'go': '[^. *\t]\.\w*'  })

" }}}

" buffer
set autoread " watch for file changes by other programs
set autowrite " automatically save before :next and :make
set hidden " when a tab is closed, do not delete the buffer

" cursor
set nostartofline " leave my cursor alone
set scrolloff=8 " keep at least 8 lines after the cursor when scrolling
set sidescrolloff=10 " (same as `scrolloff` about columns during side scrolling)
set virtualedit=block " allow the cursor to go in to virtual places
autocmd VimLeave * set guicursor=a:ver100

" command
set history=1000 " increase history size
set shell=zsh

" encoding
if has('vim_starting') | set encoding=UTF-8 | endif " ensure proper encoding
set fileencodings=utf-8 " ensure proper encoding

" error handling
set noerrorbells " turn off error bells
set visualbell t_vb= " turn off error bells

" folding
set nofoldenable
set foldmethod=marker
set foldlevelstart=99

" indentation
set autoindent " auto-indentation
set backspace=2 " fix backspace (on some OS/terminals)
set expandtab " replace tabs by spaces
set shiftwidth=2 " number of space to use for indent
set smarttab " insert `shiftwidth` spaces instead of tabs
set softtabstop=2 " n spaces when using <Tab>
set tabstop=2 " n spaces when using <Tab>

" interface
set colorcolumn=+1 " relative to text-width
set fillchars="" " remove split separators
silent! set formatoptions=croqj " format option stuff (see :help fo-table)
set laststatus=2 " always display status line
set nospell " disable spell checking
set shortmess=at " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set textwidth=80 " 80 characters line
set number " display line numbers
set mouse=a " enable mouse support
set list " display invisible chars
set listchars=tab:>· " specifically tabs and trailing spaces

augroup vimrc_help
  autocmd!
  autocmd BufEnter *.txt if &buftype == 'help' | wincmd L | endif
augroup END

" mappings {{{

  set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
  set ttimeoutlen=0 " instant insert mode exit using escape

  " disable duplicated-for-convenience mappings, to learn the correct ones
  noremap  <silent> <C-w><C-s> <Nop>
  noremap  <silent> <C-w><C-v> <Nop>
  noremap  <silent> <C-w><C-q> <Nop>

  " better `j` and `k`
  nnoremap <silent> j gj
  vnoremap <silent> j gj
  nnoremap <silent> k gk
  vnoremap <silent> k gk

  " copy from the cursor to the end of line using Y (matches D behavior)
  nnoremap <silent> Y y$

  " keep the cursor in place while joining lines
  nnoremap <silent> J mZJ`Z

  " reselect visual block after indent
  vnoremap <silent> < <gv
  vnoremap <silent> > >gv

  " clean screen and reload file
  nnoremap <silent> <C-l>      :<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-l>
  xnoremap <silent> <C-l> <C-c>:<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-l>gv

" }}}

" modeline
set modeline " enable modelines for per file configuration
set modelines=1 " consider the first/last lines

" performance
set lazyredraw " only redraw when needed
if exists('&ttyfast') | set ttyfast | endif " we have a fast terminal

" search and replace
set gdefault " default substitute g flag
set ignorecase " ignore case when searching
set incsearch " show matches as soon as possible
set smartcase " smarter search case
set wildignorecase " ignore case in file completion
set wildignore= " remove default ignores
set wildignore+=*.o,*.obj,*.so,*.a,*.dylib,*.pyc,*.hi " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar,*.rar " ignore compressed files
set wildignore+=*/.git/*,*/.hg/*,*/.svn/* " ignore SCM files
set wildignore+=*.png,*.jpg,*.jpeg,*.gif " ignore image files
set wildignore+=*.pdf,*.dmg " ignore binary files
set wildignore+=.*.sw*,*~ " ignore editor files
set wildignore+=.DS_Store " ignore OS files
set wildmenu " better command line completion menu
set wildmode=full " ensure better completion

" theme
set t_Co=256
set t_ut=
set background=dark
colorscheme nord

" undo
if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir = expand('~/.vim/tmp/undo//')
endif
