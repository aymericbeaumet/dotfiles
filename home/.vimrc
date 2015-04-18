" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles


" {{{ 1. Helpers                                                 *vimrc-helpers*

" https://github.com/EOL/cukestone/wiki/Vim-cleaning-trailing-whitespaces
" Clean all the trailing whitespaces in the current buffer
function! StripTrailingWhitespaces()
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line('.')
  let c = col('.')
  " Do the business:
  %s/\s\+$//e
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction

" http://stackoverflow.com/a/7321131/1071486
" Delete all the inactive buffers
function! DeleteInactiveBufs()
  "From tabpagebuflist() help, get a list of all buffers in all tabs
  let tablist = []
  for i in range(tabpagenr('$'))
    call extend(tablist, tabpagebuflist(i + 1))
  endfor

  "Below originally inspired by Hara Krishna Dara and Keith Roberts
  "http://tech.groups.yahoo.com/group/vim/message/56425
  let nWipeouts = 0
  for i in range(1, bufnr('$'))
    if bufexists(i) && !getbufvar(i, '&mod') && index(tablist, i) == -1
      "bufno exists AND isn't modified AND isn't in the list of buffers open in windows and tabs
      silent exec 'bwipeout' i
      let nWipeouts = nWipeouts + 1
    endif
  endfor
  echomsg nWipeouts . ' buffer(s) wiped out'
endfunction

" Create directory
function! CreateDirectory(directory_name)
  silent! call mkdir(expand(a:directory_name), 'p', 0755)
endfunction

" }}}


" {{{ 2. Preliminary

set nocompatible
au!

" }}}


" {{{ 3. Plugins                                                 *vimrc-plugins*

"    {{{ 3.1 NeoBundle

let g:bundle_dir = resolve(expand('~/.vim/bundle/'))

if has('vim_starting')
  let &rtp .= ',' . g:bundle_dir . '/neobundle.vim/'
endif

let g:neobundle#install_process_timeout = 3600 " 1 hour timeout during install/update (YCM takes a long time)

call neobundle#begin(g:bundle_dir)

NeoBundleFetch 'Shougo/neobundle.vim', {
\   'depends': [
\     [ 'Shougo/vimproc.vim', { 'build' : { 'mac' : 'make -f make_mac.mak' } } ],
\   ],
\   'vim_version': '7.2.051',
\ }

call neobundle#end()

"    }}}

"    {{{ 3.2 Languages

" Docker
NeoBundleLazy 'ekalinin/Dockerfile.vim'
au FileType =dockerfile NeoBundleSource ['ekalinin/Dockerfile.vim']

" Git
NeoBundleLazy 'tpope/vim-git'
au FileType git* NeoBundleSource ['tpope/vim-git']

" HTML
NeoBundleLazy 'othree/html5.vim'
au FileType html NeoBundleSource ['othree/html5.vim']

" Jade
NeoBundleLazy 'digitaltoad/vim-jade'
au FileType jade NeoBundleSource ['digitaltoad/vim-jade']
au BufRead,BufNewFile *.jade if &ft == '' | setfiletype jade | endif

" Javascript
let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting
NeoBundleLazy 'pangloss/vim-javascript'
NeoBundleLazy 'jelera/vim-javascript-syntax'
NeoBundleLazy 'marijnh/tern_for_vim', { 'build': { 'mac': 'npm install' } }
let g:nodejs_complete_config = { 'js_compl_fn': 'tern#Complete' }
NeoBundleLazy 'myhere/vim-nodejs-complete'
au FileType html,javascript NeoBundleSource ['pangloss/vim-javascript', 'jelera/vim-javascript-syntax', 'marijnh/tern_for_vim', 'myhere/vim-nodejs-complete']
au BufRead,BufNewFile *.es6 if &ft == '' | setfiletype javascript | endif

" JSON
NeoBundleLazy 'elzr/vim-json'
au FileType json NeoBundleSource ['elzr/vim-json']

" Markdown
NeoBundleLazy 'tpope/vim-markdown'
au FileType markdown NeoBundleSource ['tpope/vim-markdown']
au BufRead,BufNewFile *.markdown,*.mdown,*.mkdn,*.md,*.mkd,*.mdwn,*.mdtxt,*.mdtext if &ft == '' | setfiletype markdown | endif

" Nginx
NeoBundleLazy 'nginx.vim'
au FileType nginx NeoBundleSource ['nginx.vim']
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/*,*nginx.conf if &ft == '' | setfiletype nginx | endif

" Stylus
NeoBundleLazy 'wavded/vim-stylus'
au FileType stylus NeoBundleSource ['wavded/vim-stylus']
au BufRead,BufNewFile *.styl if &ft == '' | setfiletype stylus | endif

" XML
NeoBundleLazy 'matchit.zip'
autocmd FileType html,xml NeoBundleSource ['matchit.zip']

"    }}}

"    {{{ 3.3 Tools

let g:gitgutter_map_keys = 0
NeoBundle 'airblade/vim-gitgutter'

NeoBundle 'airblade/vim-rooter'

let g:airline_theme = 'badwolf' " specify theme
let g:airline_exclude_preview = 1 " remove airline from preview window
let g:airline_left_sep = '»' " change left sections separator
let g:airline_right_sep = '«' " change right sections separator
let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
let g:airline_powerline_fonts = 0 " explicitly disable powerline fonts support
NeoBundle 'bling/vim-airline', {
\   'vim_version': '7.2',
\ }
let bundle = neobundle#get('vim-airline')
function! bundle.hooks.on_post_source(bundle)
  set noshowmode " hide the duplicate mode in bottom status bar
endfunction

NeoBundle 'editorconfig/editorconfig-vim'

let g:winresizer_start_key = '<C-W><C-W>'
NeoBundle 'jimsei/winresizer'

NeoBundle 'Lokaltog/vim-easymotion'

let g:ctrlp_map = '<Leader>f'
let g:ctrlp_by_filename = 0 " search by filename and folder
let g:ctrlp_switch_buffer = 'ET' " switch to any buffer in any tab
let g:ctrlp_working_path_mode = 'ra' " set root as the nearest SCM ancestor
let g:ctrlp_clear_cache_on_exit = 0 " persistent cache
let g:ctrlp_show_hidden = 1 " search for hidden files/dirs
let g:ctrlp_custom_ignore = {
\   'dir':  '\v[\/](\.(git|hg|svn)|node_modules|bower_components|build|dist)$'
\ } " will be ignored in completion (`wildignore` is applied first)
let g:ctrlp_max_depth = 13 " avoid lag if launched in a high level directory
let g:ctrlp_open_multiple_files = '1vjr' " allow to open several files at once
let g:ctrlp_follow_symlinks = 1 " follow symlinks (but prevent infinite loops)
let g:ctrlp_mruf_case_sensitive = 1 " set case sensitive search
let g:ctrlp_mruf_save_on_update = 0 " only save MRU on Vim exit
NeoBundle 'kien/ctrlp.vim'
let bundle = neobundle#get('ctrlp.vim')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>b :CtrlPBuffer<CR>
endfunction

NeoBundle 'scrooloose/nerdcommenter'

let g:syntastic_check_on_open = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 2
let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_mode_map = {
\   'mode': 'passive',
\   'active_filetypes': ['javascript'],
\   'passive_filetypes': []
\ }
NeoBundleLazy 'scrooloose/syntastic', {
\   'build': { 'mac': 'npm install -g jshint' }
\ }
let bundle = neobundle#get('syntastic')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>s :SyntasticCheck<CR>
endfunction
au FileType javascript NeoBundleSource ['scrooloose/syntastic']

let g:UltiSnipsSnippetDirectories = ['snippet']
let g:UltiSnipsExpandTrigger = '<C-J>'
let g:UltiSnipsJumpForwardTrigger = '<C-J>'
let g:UltiSnipsJumpBackwardTrigger = '<C-K>'
NeoBundle 'SirVer/ultisnips'

NeoBundle 'tpope/vim-abolish'

NeoBundle 'tpope/vim-eunuch'

NeoBundle 'tpope/vim-fugitive'

NeoBundle 'tpope/vim-repeat'

NeoBundle 'tpope/vim-speeddating'

NeoBundle 'tpope/vim-surround'

NeoBundle 'tpope/vim-unimpaired'

let g:ycm_complete_in_comments = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_seed_identifiers_with_syntax = 1
set completeopt=longest,menuone
let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-P>', '<Up>']
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
NeoBundleLazy 'Valloric/YouCompleteMe', {
\   'build': { 'mac': './install.sh --clang-completer' },
\   'vim_version': '7.3.584',
\ }
au FileType c,cpp,javascript NeoBundleSource ['Valloric/YouCompleteMe']

"    }}}

" }}}


" {{{ 4. Theme

NeoBundle 'wombat256.vim'
silent! colorscheme wombat256mod
let bundle = neobundle#get('wombat256.vim')
function! bundle.hooks.on_post_source(bundle)
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

  " Highlight trailing whitespaces
  hi TrailingWhitespace ctermbg=darkyellow guibg=darkyellow
  match TrailingWhitespace /\s\+$/
endfunction

" }}}


" {{{ 4. Options                                                 *vimrc-options*

let g:netrw_dirhistmax = 0 " disable netrw

set autoindent           " auto-indentation
set autoread             " watch for file changes by other programs
set autowrite            " automatically save before :next and :make
set background=dark      " dark background
set backspace=2          " fix backspace (on some OS/term)
set encoding=utf-8       " ensure proper encoding
set expandtab            " replace tabs by spaces
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
set mouse=a              " enable mouse support
set nobackup             " disable backup files
set noerrorbells         " turn off error bells
set nofoldenable         " disable folding
set nostartofline        " leave my cursor position alone!
set noswapfile           " disable swap files
set scrolloff=8          " keep at least 8 lines after the cursor when scrolling
set secure               " Avoid ~/.{vimrc,exrc} modification by autocmd, shell and write
set shell=zsh            " shell for :sh
set shiftwidth=2         " n spaces when using <Tab>
set shortmess=aoOsI      " disable vim welcome message / enable shorter messages
set showcmd              " show (partial) command in the last line of the screen
set sidescrolloff=10     " (same as above about columns during side scrolling)
set smartcase            " smarter search
set smarttab             " insert `shiftwidth` spaces instead of tabs
set softtabstop=2        " n spaces when using <Tab>
set spell                " enable spell checking by default
set spellfile=~/.vim/spell/en.utf-8.add " additional spell file
set spelllang=en_us      " configure spell language
set t_Co=256             " 256 colors
set tabstop=2            " n spaces when using <Tab>
set textwidth=80         " 80 characters line
set timeoutlen=500       " time to wait when a part of a maped sequence is typped
set ttimeoutlen=0        " instant insert mode exit using escape
set ttyfast              " we have a fast terminal
set viminfo+=n~/.vim/tmp/info " change viminfo file path
set virtualedit=block    " allow the cursor to go in to virtual places
set visualbell t_vb=     " turn off error bells
set wildignore+=*.o,*.so,*.a,*.dylib,*.pyc  " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar       " ignore compressed files
set wildignore+=.*.sw*,*~                   " ignore temporary files
set wildmenu             " better command line completion menu
set wildmode=full        "  `-> ensure better completion

if has('persistent_undo')
  set undofile           " enable undo files
  set undolevels=1000    " number of undo level
  set undoreload=10000   " number of lines to save for undo
  set undodir=~/.vim/tmp/undo// " undo files directory
  au VimEnter * call CreateDirectory(&undodir)
endif

set relativenumber       " relative line numerotation by default
au InsertEnter * setl norelativenumber number " classic in insert mode
au InsertLeave * setl nonumber relativenumber " relative out of insert mode

set cursorline           " highlight cursor line
au VimEnter * hi CursorLine cterm=bold
au InsertEnter * setl nocursorline " do not highlight in insert mode
au InsertLeave * setl cursorline " highlight out of insert mode

au VimEnter * set hlsearch " highlight last search matches (only on vim startup)
au InsertEnter * setl nohlsearch " hide search highlighting in insert mode
au InsertLeave * setl hlsearch " ... and re-enable when leaving

" remember last position in file (line and column)
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | exe 'normal! g`"' | endif

" }}}


" {{{ 5. Bindings                                               *vimrc-bindings*

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

" keep the cursor in place while joining lines (uses the `l` register)
nnoremap <silent> J mlJ`l

" disable annoying keys
noremap <silent> <F1> <Nop>
inoremap <silent> <F1> <Nop>
nnoremap <silent> <C-C> <Nop>
noremap <silent> <Del> <Nop>

" center on movements
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
nnoremap <silent> # #zz

" reselect visual block after indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" insert blank lines without entering insert mode
nnoremap <silent> <Leader>O O<C-C>0"_D
nnoremap <silent> <Leader>o o<C-C>0"_D

" use `,d` `,D` `,x` `,X` to delete without altering the yanked stack
nnoremap <silent> <Leader>d "_d
vnoremap <silent> <Leader>d "_d
nnoremap <silent> <Leader>D "_D
vnoremap <silent> <Leader>D "_D
nnoremap <silent> <Leader>x "_x
vnoremap <silent> <Leader>x "_x
nnoremap <silent> <Leader>X "_X
vnoremap <silent> <Leader>X "_X

" display/hide invisible characters
nnoremap <silent> <Leader>l :set list! list?<CR>

" strip whitespaces
nnoremap <Leader>w :call StripTrailingWhitespaces()<CR>

" delete inactive buffers
nnoremap <Leader>i :call DeleteInactiveBufs()<CR>

" fix how ^Y and ^E behave in insert mode
inoremap <expr> <C-y> pumvisible() ? "\<C-y>\<C-y>" : "\<C-y>"
inoremap <expr> <C-e> pumvisible() ? "\<C-y>\<C-e>" : "\<C-e>"

" use space as an alias of the leader key
nmap <Space> <Leader>
nmap <Space><Space> <Leader><Leader>

" use control + space to enter a command
nnoremap <C-Space> :
vnoremap <C-Space> :

" }}}


" {{{ 6. Colemak stuff                                           *vimrc-colemak*

" remap in normal, visual and operator pending mode
nnoremap <silent> k j
vnoremap <silent> k j
onoremap <silent> k j
nnoremap <silent> j k
vnoremap <silent> j k
onoremap <silent> j k

" remap in normal, visual and operator pending mode
nnoremap <silent> <C-u> <C-d>
vnoremap <silent> <C-u> <C-d>
onoremap <silent> <C-u> <C-d>
nnoremap <silent> <C-d> <C-u>
vnoremap <silent> <C-d> <C-u>
onoremap <silent> <C-d> <C-u>

" }}}


" {{{ 7. Languages specific configuration                      *vimrc-languages*

au FileType css        setl shiftwidth=4 softtabstop=4 tabstop=4 iskeyword+=- iskeyword+=# iskeyword+=.
au FileType html       setl iskeyword+=- iskeyword+=# iskeyword+=.
au FileType javascript setl omnifunc=nodejscomplete#CompleteJS
au FileType make       setl noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
au FileType markdown   setl omnifunc=htmlcomplete#CompleteTags formatoptions=tcroqn2 comments=n:>

" }}}


" {{{ 8. Various

syntax enable
filetype plugin indent on

NeoBundleCheck

" Call NeoBundleLazy post source hooks again to support several consecutive `source ~/.vimrc`
call neobundle#call_hook('on_post_source')

" }}}
