" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

if !1 | finish | endif " Skip initialization for vim-tiny or vim-small

if &compatible | set nocompatible | endif " Disable Vi compatibility

syntax enable
filetype plugin indent on
let mapleader = ' '

call plug#begin('~/.vim/bundle')
  " Theme
  Plug 'altercation/solarized', { 'rtp': 'vim-colors-solarized' }

  " UI/UX
  Plug 'Lokaltog/vim-easymotion', { 'on': ['<Plug>(easymotion-s)', '<Plug>(easymotion-sn)', '<Plug>(easymotion-tn)', '<Plug>(easymotion-next)', '<Plug>(easymotion-prev)'] }
    let g:EasyMotion_do_mapping = 0 " disable the default mapping
    let g:EasyMotion_keys = 'LPUFYW;QNTESIROA' " Colemak toprow/homerow
    let g:EasyMotion_off_screen_search = 0 " do not search outside of screen
    let g:EasyMotion_smartcase = 1 " like Vim
    let g:EasyMotion_use_smartsign_us = 1 " ! and 1 are treated as the same
    let g:EasyMotion_use_upper = 1 " recognize both upper and lowercase keys
    nmap <silent> <Leader>es <Plug>(easymotion-s)
    vmap <silent> <Leader>es <Plug>(easymotion-s)
    omap <silent> <Leader>es <Plug>(easymotion-s)
    map  / <Plug>(easymotion-sn)
    omap / <Plug>(easymotion-tn)
    map  n <Plug>(easymotion-next)
    map  N <Plug>(easymotion-prev)
  Plug 'SirVer/ultisnips'
    let g:UltiSnipsExpandTrigger = '<Tab>'
    let g:UltiSnipsJumpForwardTrigger = '<Tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
    let g:UltiSnipsSnippetDirectories = ['snippet']
  Plug 'Valloric/YouCompleteMe', { 'do': './install.sh --clang-completer' }
    let g:ycm_collect_identifiers_from_comments_and_strings = 1
    let g:ycm_collect_identifiers_from_tags_files = 1
    let g:ycm_complete_in_comments = 1
    let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
    let g:ycm_key_list_previous_completion = ['<C-P>', '<Up>']
    let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
    let g:ycm_seed_identifiers_with_syntax = 1
    set completeopt=longest,menuone
  Plug 'airblade/vim-gitgutter'
    let g:gitgutter_escape_grep = 1
    let g:gitgutter_map_keys = 0
  Plug 'airblade/vim-rooter'
    let g:rooter_change_directory_for_non_project_files = 1 " chdir even when not in a project
    let g:rooter_disable_map = 1 " do not map any bindings
    let g:rooter_silent_chdir = 1 " do not notify when changing directory
    let g:rooter_use_lcd = 1 " change the cd on a per window basis
  Plug 'bling/vim-airline'
    let g:airline_exclude_preview = 1 " remove airline from preview window
    let g:airline_left_sep = '' " remove left separator
    let g:airline_powerline_fonts = 0 " explicitly disable powerline fonts support
    let g:airline_right_sep = '' " remove right separator
    let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
    let g:airline_theme = 'solarized' " specify theme
    set noshowmode " hide the duplicate mode in bottom status bar
  Plug 'editorconfig/editorconfig-vim'
    let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
  Plug 'jimsei/winresizer'
    let g:winresizer_start_key = '<C-W><C-W>'
  Plug 'junegunn/limelight.vim' | Plug 'junegunn/goyo.vim'
    autocmd! User GoyoEnter Limelight
    autocmd! User GoyoLeave Limelight!
  Plug 'scrooloose/nerdcommenter'
    let g:NERDCommentWholeLinesInVMode = 1
    let g:NERDMenuMode = 0
    let g:NERDSpaceDelims = 1
  Plug 'scrooloose/syntastic', { 'on': 'javascript' }
    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_aggregate_errors = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_javascript_checkers = ['eslint']
    let g:syntastic_mode_map = {
    \   'mode': 'passive',
    \   'active_filetypes': ['javascript'],
    \   'passive_filetypes': [],
    \ }
  Plug 'tpope/vim-abolish'
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-speeddating'
  Plug 'tpope/vim-surround'
    let g:surround_indent = 1 " reindent with `=` after surrounding
    let g:surround_no_insert_mappings = 1 " disable the default mapping
  Plug 'tpope/vim-unimpaired'

  " Docker
  Plug 'ekalinin/Dockerfile.vim', { 'for': 'docker' }

  " Git
  Plug 'tpope/vim-git'

  " Javascript
  Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
    let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting
  Plug 'jelera/vim-javascript-syntax', { 'for': 'javascript' }
  Plug 'marijnh/tern_for_vim', { 'for': 'javascript', 'do': 'npm install' }
  Plug 'myhere/vim-nodejs-complete', { 'for': 'javascript' }
    let g:nodejs_complete_config = { 'js_compl_fn': 'tern#Complete' }

   " JSON
  Plug 'elzr/vim-json', { 'for': 'json' }

  " Markdown
  Plug 'tpope/vim-markdown', { 'for': 'markdown' }
call plug#end()

let b:tmp_directory = expand('~/.vim/tmp') " define the temporary directory

" encoding
set encoding=utf-8 " ensure proper encoding
set fileencodings=utf-8 " ensure proper encoding

" indentation
set autoindent " auto-indentation
set backspace=2 " fix backspace (on some OS/term)
set expandtab " replace tabs by spaces
set shiftwidth=2 " n spaces when using <Tab>
set smarttab " insert `shiftwidth` spaces instead of tabs
set softtabstop=2 " n spaces when using <Tab>
set tabstop=2 " n spaces when using <Tab>

" modeline
set modeline " enable modelines for per file configuration
set modelines=1 " consider the first/last lines

" history
set history=1000 " increase history size

" performance
set lazyredraw " only redraw when needed
set ttyfast " we have a fast terminal

" search and replace behaviours
set gdefault " default substitute g flag
set ignorecase " ignore case when searching
set incsearch " show matches as soon as possible
set smartcase " smarter search
set wildignore+=*.o,*.so,*.a,*.dylib,*.pyc " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar " ignore compressed files
set wildignore+=.*.sw*,*~ " ignore temporary files
set wildmenu " better command line completion menu
set wildmode=full "  `-> ensure better completion

" disable error notifications
set noerrorbells " turn off error bells
set visualbell t_vb= " turn off error bells

" ui/ux
set autoread " watch for file changes by other programs
set autowrite " automatically save before :next and :make
set formatoptions=croqj " format option stuff (see :help fo-table)
set hidden " when a tab is closed, do not delete the buffer
set laststatus=2 " always display status line
set nofoldenable " disable folding
set nostartofline " leave my cursor position alone!
set scrolloff=8 " keep at least 8 lines after the cursor when scrolling
set shell=zsh " shell for :sh
set shortmess=aoOsI " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set sidescrolloff=10 " (same as `scrolloff` about columns during side scrolling)
set splitbelow " slit below
set splitright " split right
set t_Co=256 " 256 colors
set textwidth=80 " 80 characters line
set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
set ttimeoutlen=0 " instant insert mode exit using escape
set virtualedit=block " allow the cursor to go in to virtual places

" vim
let g:netrw_dirhistmax = 0 " disable netrw
let &viminfo = &viminfo + ',n' . b:tmp_directory . '/info' " change viminfo file path
set nobackup " disable backup files
set noswapfile " disable swap files

" theme configuration
set background=dark
set colorcolumn=+1 " relative to text-width
colorscheme solarized

" mouse
if has('mouse')
  set mouse=a
endif

" spell checking
if !has('nvim')
  set spell
  set spellfile=~/.vim/spell/en.utf-8.add
endif

" persistent undo
if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir = b:tmp_directory . '/undo//'
endif

" better `j` and `k`
nnoremap <silent> j gj
vnoremap <silent> j gj
nnoremap <silent> k gk
vnoremap <silent> k gk

" hide last search matches, refresh screen, re-read current buffer
" See: http://www.reddit.com/r/vim/comments/1vdrxg/space_is_a_big_key_what_do_you_map_it_to/ceri6yf
nnoremap <silent> <C-L>      :nohl<CR>:redraw<CR>:checktime<CR><C-L>
vnoremap <silent> <C-L> <C-C>:nohl<CR>:redraw<CR>:checktime<CR><C-L>gv

" copy from the cursor to the end of line using Y (matches D behavior)
nnoremap <silent> Y y$

" keep the cursor in place while joining lines (uses the `b` register, very
" unaccessible on a Colemak layout)
nnoremap <silent> J mbJ`b

" disable useless/annoying keys
noremap  <silent> <F1>  <Nop>
inoremap <silent> <F1>  <Nop>
nnoremap <silent> <C-C> <Nop>
noremap  <silent> <Del> <Nop>

" reselect visual block after indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" fix how ^E and ^Y behave in insert mode
inoremap <silent><expr> <C-e> pumvisible() ? "\<C-y>\<C-e>" : "\<C-e>"
inoremap <silent><expr> <C-y> pumvisible() ? "\<C-y>\<C-y>" : "\<C-y>"

" [w]rite the current buffer (uppercase forces overwrite)
nnoremap <silent> <Leader>w :w<CR>
nnoremap <silent> <Leader>W :w!<CR>

" [q]uit the current buffer (uppercase forces to quit)
nnoremap <silent> <Leader>q :q<CR>
nnoremap <silent> <Leader>Q :q!<CR>

" highlight cursor line (except while being in insert mode)
set cursorline
au VimEnter * hi CursorLine cterm=bold
au InsertEnter * setl nocursorline
au InsertLeave * setl cursorline

" highlight search matches (except while being in insert mode)
au VimEnter * set hlsearch
au InsertEnter * setl nohlsearch
au InsertLeave * setl hlsearch

" remember last position in file (line and column)
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute 'normal! g`"' | endif

" automatically remove trailing whitespace
au BufWritePre * :%s/\s\+$//e

" Avoid ~/.{vimrc,exrc} modification by autocmd, shell and write
set secure
