" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

" Skip initialization for vim-tiny or vim-small
if !1 | finish | endif

" Disable Vi compatibility
if &compatible
  set nocompatible
endif

" Delete existing autocommands
au!

" {{{ Configuration

" Remap leader key to space (need to be done before any other mapping)
let mapleader = ' '

" Define the temporary directory
let b:tmp_directory = expand('~/.vim/tmp')

" }}}

" {{{ Plugins

" Start NeoBundle initialization

let g:bundle_dir = resolve(expand('~/.vim/bundle'))

if has('vim_starting')
  let &rtp .= ',' . g:bundle_dir . '/neobundle.vim/'
endif

call neobundle#begin(g:bundle_dir)

" Load plugins (if possible, use the NeoBundle cache)

if neobundle#load_cache()

  " Bundles dependencies

  NeoBundleLazy 'Shougo/vimproc.vim', {
  \   'build' : {
  \     'mac': 'make -f make_mac.mak',
  \     'linux': 'make',
  \   },
  \ }

  " NeoBundle

  NeoBundleFetch 'Shougo/neobundle.vim', {
  \   'depends': ['Shougo/vimproc.vim'],
  \   'vim_version': '7.2.051',
  \ }

  " Docker

  NeoBundle 'ekalinin/Dockerfile.vim'

  " Git

  NeoBundle 'airblade/vim-gitgutter', {
  \   'disabled': !executable('git'),
  \ }

  NeoBundle 'tpope/vim-git', {
  \   'disabled': !executable('git'),
  \ }

  NeoBundle 'tpope/vim-fugitive', {
  \   'disabled': !executable('git'),
  \ }

  " Interface

  NeoBundle 'bling/vim-airline', {
  \   'depends': ['tpote/vim-fugitive', 'airblade/vim-gitgutter', 'scrooloose/syntastic'],
  \   'vim_version': '7.2',
  \ }

  NeoBundle 'jimsei/winresizer'

  " Javascript

  NeoBundle 'pangloss/vim-javascript'

  NeoBundle 'jelera/vim-javascript-syntax'

  NeoBundle 'marijnh/tern_for_vim', {
  \   'build': {
  \     'mac': 'npm install',
  \     'linux': 'npm install',
  \   },
  \ }

  NeoBundle 'myhere/vim-nodejs-complete'

  " JSON

  NeoBundle 'elzr/vim-json'

  " Markdown

  NeoBundle 'tpope/vim-markdown'

  " Motion

  NeoBundle 'Lokaltog/vim-easymotion'

  " Theme

  NeoBundle 'wombat256.vim'

  " Workflow

  NeoBundle 'airblade/vim-rooter'

  NeoBundle 'editorconfig/editorconfig-vim'

  NeoBundle 'scrooloose/nerdcommenter', {
  \   'vim_version': '7',
  \ }

  NeoBundle 'scrooloose/syntastic', {
  \   'vim_version': '7',
  \   'disabled': !has('autocmd') || !has('eval') || !has('file_in_path') || !has('modify_fname') || !has('quickfix') || !has('reltime') || !has('user_commands'),
  \ }

  NeoBundle 'SirVer/ultisnips', {
  \   'disabled': !has('python'),
  \ }

  NeoBundle 'tpope/vim-abolish'

  NeoBundle 'tpope/vim-eunuch'

  NeoBundle 'tpope/vim-repeat'

  NeoBundle 'tpope/vim-speeddating'

  NeoBundle 'tpope/vim-surround'

  NeoBundle 'tpope/vim-unimpaired'

  if has('macunix') " only run on OSX workstation (not on Linux servers)
  NeoBundle 'Valloric/YouCompleteMe', {
  \   'install_process_timeout': 3600,
  \   'build': {
  \     'mac': './install.sh --clang-completer',
  \   },
  \   'vim_version': '7.3.584',
  \   'disabled': !has('python'),
  \ }
  endif

  NeoBundleSaveCache

endif

" Setup plugins

let bundle = neobundle#get('syntastic')
function! bundle.hooks.on_source(bundle)
  let g:syntastic_check_on_open = 1
  let g:syntastic_always_populate_loc_list = 1
  let g:syntastic_auto_loc_list = 2
  let g:syntastic_javascript_checkers = ['eslint']
  let g:syntastic_mode_map = {
  \   'mode': 'passive',
  \   'active_filetypes': ['javascript'],
  \   'passive_filetypes': [],
  \ }
endfunction
function! bundle.hooks.on_post_source(bundle)
  execute 'nnoremap <silent> <Leader>l :SyntasticCheck<CR>'
endfunction

let bundle = neobundle#get('ultisnips')
function! bundle.hooks.on_source(bundle)
  let g:UltiSnipsSnippetDirectories = ['snippet']
  let g:UltiSnipsExpandTrigger = '<C-J>'
  let g:UltiSnipsJumpForwardTrigger = '<C-J>'
  let g:UltiSnipsJumpBackwardTrigger = '<C-K>'
endfunction

let bundle = neobundle#get('vim-airline')
function! bundle.hooks.on_source(bundle)
  let g:airline_theme = 'badwolf' " specify theme
  let g:airline_exclude_preview = 1 " remove airline from preview window
  let g:airline_powerline_fonts = 0 " explicitly disable powerline fonts support
  let g:airline_left_sep = '' " remove left separator
  let g:airline_right_sep = '' " remove right separator
  let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
  let g:airline#extensions#tabline#enabled = 1 " display buffer line
endfunction
function! bundle.hooks.on_post_source(bundle)
  set noshowmode " hide the duplicate mode in bottom status bar
endfunction

let bundle = neobundle#get('vim-easymotion')
function! bundle.hooks.on_source(bundle)
  let g:EasyMotion_keys = 'LPUFYW;QNTESIROA' " Colemak toprow/homerow
  let g:EasyMotion_smartcase = 1 " like Vim
  let g:EasyMotion_use_upper = 1 " recognize both upper and lowercase keys
  let g:EasyMotion_use_smartsign_us = 1 " ! and 1 are treated as the same
  let g:EasyMotion_off_screen_search = 0 " do not search outside of screen
endfunction
function! bundle.hooks.on_post_source(bundle)
  silent! unmap <Leader><Leader>
  execute 'nmap <silent> <Leader>e <Plug>(easymotion-prefix)'
  execute 'vmap <silent> <Leader>e <Plug>(easymotion-prefix)'
  execute 'omap <silent> <Leader>e <Plug>(easymotion-prefix)'
endfunction

let bundle = neobundle#get('vim-gitgutter')
function! bundle.hooks.on_source(bundle)
  let g:gitgutter_map_keys = 0
endfunction

let bundle = neobundle#get('vim-javascript')
function! bundle.hooks.on_source(bundle)
  let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting
endfunction

let bundle = neobundle#get('vim-nodejs-complete')
function! bundle.hooks.on_source(bundle)
  let g:nodejs_complete_config = { 'js_compl_fn': 'tern#Complete' }
endfunction

let bundle = neobundle#get('vim-surround')
function! bundle.hooks.on_source(bundle)
  let g:surround_no_insert_mappings = 1 " not insert mappings
  let g:surround_indent = 1 " reindent with `=` after surrounding
endfunction

let bundle = neobundle#get('vim-rooter')
function! bundle.hooks.on_source(bundle)
  let g:rooter_disable_map = 1 " do not map any bindings
  let g:rooter_silent_chdir = 1 " do not notify when changing directory
  let g:rooter_change_directory_for_non_project_files = 1 " chdir even when not in a project
  let g:rooter_use_lcd = 1 " change the cd on a per window basis
endfunction

let bundle = neobundle#get('winresizer')
function! bundle.hooks.on_source(bundle)
  let g:winresizer_start_key = '<C-W><C-W>'
endfunction

let bundle = neobundle#get('wombat256.vim')
function! bundle.hooks.on_post_source(bundle)
  " enable theme
  silent! colorscheme wombat256mod
  " Change spell detection skin
  hi clear SpellBad
  hi clear SpellCap
  hi clear SpellLocal
  hi clear SpellRare
  hi SpellBad cterm=underline gui=underline
  hi SpellCap cterm=underline gui=underline
  hi SpellLocal cterm=underline gui=underline
  hi SpellRare cterm=underline gui=underline
  " Highlight color column
  set colorcolumn=+1 " relative to text-width
  hi ColorColumn ctermbg=0 guibg=black
endfunction

if neobundle#is_sourced('YouCompleteMe')
let bundle = neobundle#get('YouCompleteMe')
function! bundle.hooks.on_source(bundle)
  let g:ycm_complete_in_comments = 1
  let g:ycm_collect_identifiers_from_tags_files = 1
  let g:ycm_seed_identifiers_with_syntax = 1
  let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
  let g:ycm_key_list_previous_completion = ['<C-P>', '<Up>']
  let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
endfunction
function! bundle.hooks.on_post_source(bundle)
  set completeopt=longest,menuone
endfunction
endif

" End NeoBundle initialization

NeoBundleCheck

call neobundle#end()

" }}}

" {{{ Mappings

" up and down are more logical with g
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

" keep the cursor in place while joining lines (uses the `j` register)
nnoremap <silent> J mjJ`j

" disable annoying keys
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

" [c] NerdCommenter prefix
" <Leader>c

" [d]elete the current buffer (lowercase saves it before / uppercase trashes the
" modifications)
nnoremap <silent> <Leader>d :w<CR>:bd<CR>
nnoremap <silent> <Leader>D :bd!<CR>

" [e]asymotion prefix
" <Leader>e

" [r]eload the configuration
nnoremap <silent> <Leader>r :source ~/.vimrc<CR>

" [w]rite the current buffer
nnoremap <silent> <Leader>w :w<CR>
nnoremap <silent> <Leader>W :w!<CR>

" [q]uit the current buffer (uppercase trashes the modifications)
nnoremap <silent> <Leader>q :q<CR>
nnoremap <silent> <Leader>Q :q!<CR>

" }}}

" {{{ Options

let g:netrw_dirhistmax = 0 " disable netrw

set autoindent           " auto-indentation
set autoread             " watch for file changes by other programs
set autowrite            " automatically save before :next and :make
set background=dark      " dark background
set backspace=2          " fix backspace (on some OS/term)
set encoding=utf-8       " ensure proper encoding
set expandtab            " replace tabs by spaces
set fileencodings=utf-8  " ensure proper encoding
set formatoptions=croqj  " format option stuff (see :help fo-table)
set gdefault             " default substitute g flag
set hidden               " when a tab is closed, do not delete the buffer
set history=1000         " increase history size
set ignorecase           " ignore case when searching
set incsearch            " show matches as soon as possible
set laststatus=2         " always display status line
set lazyredraw           " only redraw when needed
set modeline             " enable modelines for per file configuration
set modelines=3          " consider the first/last three lines
set nobackup             " disable backup files
set noerrorbells         " turn off error bells
set nofoldenable         " disable folding
set nostartofline        " leave my cursor position alone!
set noswapfile           " disable swap files
set scrolloff=8          " keep at least 8 lines after the cursor when scrolling
set shell=zsh            " shell for :sh
set shiftwidth=2         " n spaces when using <Tab>
set shortmess=aoOsI      " disable vim welcome message / enable shorter messages
set showcmd              " show (partial) command in the last line of the screen
set sidescrolloff=10     " (same as `scrolloff` about columns during side scrolling)
set smartcase            " smarter search
set smarttab             " insert `shiftwidth` spaces instead of tabs
set softtabstop=2        " n spaces when using <Tab>
set spell                " enable spell checking by default
set spellfile=~/.vim/spell/en.utf-8.add " additional spell file
set spelllang=en_us      " configure spell language
set t_Co=256             " 256 colors
set tabstop=2            " n spaces when using <Tab> (may be overriden for specific filetypes)
set textwidth=80         " 80 characters line
set timeoutlen=500       " time to wait when a part of a mapped sequence is typed
set ttimeoutlen=0        " instant insert mode exit using escape
set ttyfast              " we have a fast terminal
let &viminfo = &viminfo + ',n' . b:tmp_directory . '/info' " change viminfo file path
set virtualedit=block    " allow the cursor to go in to virtual places
set visualbell t_vb=     " turn off error bells
set wildignore+=*.o,*.so,*.a,*.dylib,*.pyc  " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar       " ignore compressed files
set wildignore+=.*.sw*,*~                   " ignore temporary files
set wildmenu             " better command line completion menu
set wildmode=full        "  `-> ensure better completion
set splitbelow           " slit below
set splitright           " split right

if has('mouse')          " enable mouse support
  set mouse=a
  if has('mouse_sgr') || v:version > 703 || v:version == 703 && has('patch632')
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  endif
endif

if has('persistent_undo')
  set undofile           " enable undo files
  set undolevels=1000    " number of undo level
  set undoreload=10000   " number of lines to save for undo
  let &undodir = b:tmp_directory . '/undo//' " undo files directory
endif

au VimEnter * set relativenumber " relative line numbering by default
au InsertEnter * setl norelativenumber number " classic in insert mode
au InsertLeave * setl nonumber relativenumber " relative out of insert mode

set cursorline           " highlight cursor line
au VimEnter * hi CursorLine cterm=bold
au InsertEnter * setl nocursorline " do not highlight in insert mode
au InsertLeave * setl cursorline " highlight out of insert mode

au VimEnter * set hlsearch " highlight last search matches
au InsertEnter * setl nohlsearch " hide search highlighting in insert mode
au InsertLeave * setl hlsearch " ... and re-enable when leaving

" remember last position in file (line and column)
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute 'normal! g`"' | endif

" automatically remove trailing whitespace
au BufWritePre * :%s/\s\+$//e

" }}}

" Enable syntax
syntax enable

" Enable filetypes detection
filetype plugin indent on

" Call NeoBundle post source hooks again to support several consecutive `source
" ~/.vimrc`
call neobundle#call_hook('on_post_source')

" Avoid ~/.{vimrc,exrc} modification by autocmd, shell and write. It has to be
" at the end of the .vimrc
set secure
