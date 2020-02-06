" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
" Github: @aymericbeaumet/dotfiles

" init {{{

  filetype plugin indent on
  if has('vim_starting') | set encoding=UTF-8 | endif
  set fileencodings=utf-8
  scriptencoding utf-8
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))
    Plug 'airblade/vim-rooter'
    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb' | Plug 'shumphrey/fugitive-gitlab.vim'
    Plug 'moll/vim-bbye' | Plug 'aymericbeaumet/vim-symlink'
    Plug 'jceb/vim-orgmode'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-speeddating'
    Plug 'tpope/vim-eunuch'
    Plug 'scrooloose/nerdcommenter'
    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_keys = 'X.Z/C,VMBKQ;WYFUPLAORISETN'
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_use_upper = 1
    Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
  call plug#end()

" }}}

" commands {{{

  command! -bang -nargs=* RgWithHiddenFiles call fzf#vim#grep("rg --hidden --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>), 1, <bang>0)

" }}}

" mappings {{{

  set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
  set ttimeoutlen=0 " instant insert mode exit using escape

  nnoremap <silent> <Leader>/ :BLines<CR>
  nnoremap <silent> <Leader>b :Buffers<CR>
  nnoremap <silent> <Leader>c :Commands<CR>
  nnoremap <silent> <Leader>d :bd<CR>
  nnoremap <silent> <Leader>e :Explore<CR>
  nnoremap <silent> <Leader>f :Files<CR>
  nnoremap <silent> <Leader>r :Rg<CR>
  nnoremap <silent> <Leader>R :RgWithHiddenFiles<CR>
  nnoremap <silent> <Leader>q :q<CR>

  nnoremap <silent> <Leader>gb :Gbrowse<CR>
  nnoremap <silent> <Leader>gd :Gvdiffsplit<CR>
  nnoremap <silent> <Leader>gf :GitFiles<CR>
  nnoremap <silent> <Leader>gl :Commits<CR>
  nnoremap <silent> <Leader>gs :Gstatus<CR>

  " save current buffer
  nnoremap <CR> :w<CR>

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

  " : and / supports <C-R> to call FZF (https://github.com/junegunn/fzf.vim/issues/264#issuecomment-265898760)
  function! s:FzfCommandHistory()
    let s:INTERRUPT = "\u03\u0c" " <C-c><C-l>
    let s:SUBMIT = "\u0d" " <C-m>
    let s:cmdtype = getcmdtype()
    let s:args = string({
          \   "options": "--query=" . shellescape(getcmdline()),
          \ })
    if s:cmdtype == ':'
      return s:INTERRUPT . ":keepp call fzf#vim#command_history(" .  s:args . ")" . s:SUBMIT
    elseif s:cmdtype == '/'
      return s:INTERRUPT . ":keepp call fzf#vim#search_history(" .  s:args . ")" . s:SUBMIT
    else
      return ''
    endif
  endfunction
  cnoremap <expr> <C-r> <SID>FzfCommandHistory()

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

" command
set history=10000 " increase history size

" indentation
set autoindent " auto-indentation
set backspace=2 " fix backspace (on some OS/terminals)
set expandtab " replace tabs by spaces
set shiftwidth=2 " number of space to use for indent
set smarttab " insert `shiftwidth` spaces instead of tabs
set softtabstop=2 " n spaces when using <Tab>
set tabstop=2 " n spaces when using <Tab>

" interface
syntax off
set fillchars="" " remove split separators
set laststatus=2 " always display status line
set nospell " disable spell checking
set shortmess=at " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set mouse=a " enable mouse support

" performance
set lazyredraw " only redraw when needed
if exists('&ttyfast') | set ttyfast | endif " we have a fast terminal

" search and replace
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

" undo
if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir = expand('~/.vim/tmp/undo//')
endif

" open the help pane vertically
augroup vimrc_help
  autocmd!
  autocmd BufEnter *.txt if &buftype == 'help' | wincmd L | endif
augroup END
