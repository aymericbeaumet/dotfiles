" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
" Github: @aymericbeaumet/dotfiles

" todo {{{
"   - fix filename relative to cwd (sometime going crazy)
" }}}

" init {{{

  if !1 | finish | endif " Skip initialization for vim-tiny or vim-small

  if exists('&compatible') | set nocompatible | endif " 21st century

  syntax enable
  filetype plugin indent on
  let mapleader = ' '

" }}}

" plugins {{{

  augroup vimrc_inlined_plugins
    autocmd!
    " highlight search matches (except while being in insert mode)
    autocmd VimEnter,BufReadPost,InsertLeave * setl hlsearch
    autocmd InsertEnter * setl nohlsearch
  augroup END

  call plug#begin(expand('~/.vim/bundle'))

  " plugins > configuration {{{

    Plug 'embear/vim-localvimrc'
      let g:localvimrc_sandbox = 0
      let g:localvimrc_ask = 0

    Plug 'airblade/vim-rooter'
      let g:rooter_change_directory_for_non_project_files = 'current'
      let g:rooter_use_lcd = 1
      let g:rooter_silent_chdir = 1
      let g:rooter_resolve_links = 1

    Plug 'editorconfig/editorconfig-vim'

    Plug 'dietsche/vim-lastplace'

    Plug 'aymericbeaumet/symlink.vim'

    Plug 'vitalk/vim-shebang'

  " }}}

  " plugins > interface {{{

    Plug 'altercation/vim-colors-solarized'

    Plug 'vim-airline/vim-airline-themes' | Plug 'vim-airline/vim-airline'
      set noshowmode " hide the duplicate mode in bottom status bar
      let g:airline_theme = 'solarized'
      let g:airline_powerline_fonts = 1
      function! s:AirlineInit()
        let g:airline_section_a = airline#section#create_left([
        \   '%{isdirectory(getcwd() . "/.git") ? fnamemodify(getcwd(), ":t") : getcwd()}',
        \   '%{expand("%")}',
        \ ])
        let g:airline_section_b = airline#section#create_left([
        \   'branch',
        \   'hunks',
        \ ])
        let g:airline_section_c = airline#section#create_left([
        \ ])
        let g:airline_section_x = airline#section#create_right([
        \ ])
        let g:airline_section_y = airline#section#create_right([
        \   '%{empty(&filetype) ? "(no type)" : &filetype}',
        \   '%{empty(&fileencoding) ? "(no encoding)" : &fileencoding}',
        \   '%{empty(&fileformat) ? "(no format)" : &fileformat}',
        \ ])
        let g:airline_section_z = airline#section#create_right([
        \   '%p%%',
        \   "\uE0A1%l:\uE0A3%c",
        \ ])
        let g:airline_section_warning = airline#section#create_right([
        \   'whitespace',
        \   'neomake_warning_count',
        \ ])
        let g:airline_section_error = airline#section#create_right([
        \   'neomake_error_count',
        \ ])
      endfunction
      augroup vimrc_airline
        autocmd!
        autocmd User AirlineAfterInit call s:AirlineInit()
      augroup END

    Plug 'luochen1990/rainbow'

  " }}}

  " plugins > zsh {{{

    Plug 'edkolev/promptline.vim'
      let g:promptline_powerline_symbols = 1

  " }}}

  " plugins > productivity {{{

    Plug 'Lokaltog/vim-easymotion'
      map <silent> <Leader>e <Plug>(easymotion-prefix)
      let g:EasyMotion_keys = 'LPUFYW;QNTESIROA' " Colemak toprow/homerow
      let g:EasyMotion_off_screen_search = 1 " do not search outside of screen
      let g:EasyMotion_smartcase = 1 " like Vim
      let g:EasyMotion_use_smartsign_us = 1 " ! and 1 are treated as the same
      let g:EasyMotion_use_upper = 1 " recognize both upper and lowercase keys

    Plug 'scrooloose/nerdcommenter'
      let g:NERDCommentWholeLinesInVMode = 1
      let g:NERDMenuMode = 0
      let g:NERDSpaceDelims = 1

    Plug 'tpope/vim-eunuch'

    Plug 'tpope/vim-fugitive'
      let g:fugitive_no_maps = 1

    Plug 'tpope/vim-repeat'

    Plug 'tpope/vim-surround'
      nmap <silent> cs <Plug>Csurround
      nmap <silent> ds <Plug>Dsurround
      let g:surround_no_mappings = 1 " disable the default mappings
      let g:surround_indent = 1 " reindent with `=` after surrounding

    Plug 'tpope/vim-unimpaired'

    Plug 'qpkorr/vim-bufkill'
      let g:BufKillCreateMappings = 0
      nnoremap <silent> <Leader>d :<C-u>BD<CR>

  " }}}

  " plugins > syntax {{{

    " javascript
    Plug 'pangloss/vim-javascript'

    " json
    Plug 'elzr/vim-json'

    " markdown
    Plug 'gabrielelana/vim-markdown'
      let g:markdown_enable_mappings = 0
      let g:markdown_enable_spell_checking = 1

  " }}}

  call plug#end()

  let g:promptline_preset = {
  \   'a': [
  \     '%~',
  \   ],
  \   'b': [
  \     promptline#slices#vcs_branch(),
  \     promptline#slices#git_status(),
  \   ],
  \   'c': [
  \     promptline#slices#jobs(),
  \   ],
  \   'warn': [
  \     promptline#slices#last_exit_code(),
  \   ],
  \ }

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
set history=1000 " increase history size
set shell=zsh

" encoding
if has('vim_starting') | set encoding=utf8 | endif " ensure proper encoding
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
set number " show the line numbers
set shortmess=aoOsI " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set textwidth=80 " 80 characters line

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

  " [s]ort
  vnoremap <silent> <Leader>s :sort<CR>

  " [R]eload configuration
  nnoremap <silent> <Leader>R  :<C-u>source $MYVIMRC<CR>:echom 'Vim configuration reloaded!'<CR>

" }}}

" modeline
set modeline " enable modelines for per file configuration
set modelines=1 " consider the first/last lines

" mouse
if has('mouse')
  set mouse=a
  if exists('&ttyscroll') | set ttyscroll=1 | endif
  if exists('&ttymouse') | set ttymouse=xterm2 | endif
endif

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
set background=dark
colorscheme solarized

" undo
if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir = expand('~/.vim/tmp/undo//')
endif

" vim
if has('nvim')
set viminfo=%,<800,'10,/50,:100,h,f0,n~/.vim/tmp/nviminfo
else
set viminfo=%,<800,'10,/50,:100,h,f0,n~/.vim/tmp/viminfo
endif
set nobackup " disable backup files
set noswapfile " disable swap files
set secure " protect the configuration files

" MacVim (https://github.com/macvim-dev/macvim) {{{
if has('gui_macvim')
" Disable antialiasing with `!defaults write org.vim.MacVim AppleFontSmoothing -int 0`
" Set the font
silent! set guifont=Monaco:h12 " fallback
silent! set guifont=FiraCode-Light:h12 " preferred
" Disable superfluous GUI stuff
set guicursor=
set guioptions=
" Use console dialog instead of popup
set guioptions+=c
" Disable cursor blinking
set guicursor+=a:blinkon0
" Set the cursor as an underscore
set guicursor+=a:hor8
endif
" }}}

" Neovim.app (https://github.com/neovim/neovim) {{{
if exists('neovim_dot_app')
" Disable antialiasing with `!defaults write uk.foon.Neovim AppleFontSmoothing -int 0`
" Set the font
silent! call MacSetFont('Monaco', 12) " fallback
silent! call MacSetFont('FiraCode-Light', 12) " preferred
" Enable anti-aliasing (see above to disable the ugly AA from OSX)
call MacSetFontShouldAntialias(1)
endif
" }}}
