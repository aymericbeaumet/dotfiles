" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles
"
" Content:
"   1. Helpers                                      *vimrc-helpers*
"   2. Global options                               *vimrc-options*
"   3. User Interface                               *vimrc-ui*
"   4. Search & Replace behavior                    *vimrc-search*
"   5. Text editing                                 *vimrc-edition*
"   6. Indentation / Tabulations                    *vimrc-indent-tab*
"   7. Errors                                       *vimrc-errors*
"   8. Binds & Alias                                *vimrc-binds-alias*
"   9. Languages specific configuration             *vimrc-languages*
"  10. Plugins                                      *vimrc-plugins*
"     10.1. NeoBundle                                  *vimrc-plugins-neobundle*
"     10.2. Themes                                     *vimrc-plugins-themes*
"     10.3. Languages specific plugins                 *vimrc-plugins-languages*
"     10.4. Tools plugins                              *vimrc-plugins-tools*
"  11. File type / Syntax detection                 *vimrc-filetype*



" break away from old vi compatibility
set nocompatible

" clear autocommands of the default group
au!



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

" Detect Linux/BSD
function! IsLinuxBSD()
  return has('unix') && !IsMac()
endfunction

" Detect Mac
function! IsMac()
  return has('mac') || has('macunix')
endfunction

" Detect Windows
function! IsWindows()
  return has('win16') || ('win32') || ('win64') || ('win95') || ('win32unix')
endfunction

" Properly abbreviate a command
function! AbbreviateCommand(abbreviation, expansion)
  execute 'cnoreabbrev <expr> ' . a:abbreviation . ' ((getcmdtype() is# ":" && getcmdline() is# "' . a:abbreviation . '") ? ("' . a:expansion . '") : ("' . a:abbreviation . '"))'
endfunction

" }}}



" {{{ 2. Global options                                          *vimrc-options*

set shell=zsh           " shell for :sh
set autoread            " watch for file changes by other programs
set autowrite           " automatically save before :next and :make
set encoding=utf-8      " ensure proper encoding
set ttyfast             " we have a fast terminal
set modeline            " enable modelines
set modelines=3         " consider the first/last three lines
set history=1000        " increase history size

set noswapfile          " disable swap files
let g:netrw_dirhistmax = 0 " disable netrw

set viminfo+=n~/.vim/tmp/info " change viminfo file path

set backup              " enable backup files
set backupdir=~/.vim/tmp/backup// " backup files directory
au VimEnter * call CreateDirectory(&backupdir)

if has('persistent_undo')
  set undofile            " enable undo files
  set undolevels=1000     " number of undo level
  set undoreload=10000    " number of lines to save for undo
  set undodir=~/.vim/tmp/undo// " undo files directory
  au VimEnter * call CreateDirectory(&undodir)
endif

" }}}



" {{{ 3. User Interface                                               *vimrc-ui*

set timeoutlen=500      " time to wait when a part of a maped sequence is typped
set ttimeoutlen=0       " instant insert mode exit using escape
set matchtime=3         " tenths of second to show the matching bracket
set cmdheight=1         " explicitly set the command line height
set showcmd             " show (partial) command in the last line of the screen
set lazyredraw          " only redraw when needed
set shortmess=aoOsI     " disable vim welcome message / enable shorter messages
set wildmenu            " better command line completion menu
set wildmode=full       "  `-> ensure better completion
set wildignore+=*.o,*.so,*.a,*.dylib,*.pyc  " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar       " ignore compressed files
set wildignore+=.*.sw*,*~                   " ignore temporary files
set hidden              " when a tab is closed, do not delete the buffer
set laststatus=2        " always display status line
set t_Co=256            " 256 colors
set mouse=a             " enable mouse support
set background=dark     " dark background

" highlight cursor line
au VimEnter * hi CursorLine cterm=bold

set relativenumber      " relative line numerotation by default
au InsertEnter * setl norelativenumber number " classic in insert mode
au InsertLeave * setl nonumber relativenumber " relative out of insert mode

set cursorline          " highlight cursor line
au InsertEnter * setl nocursorline " do not highlight in insert mode
au InsertLeave * setl cursorline " highlight out of insert mode

" }}}



" {{{ 4. Search & Replace behavior                                *vimrc-search*

set ignorecase          " ignore case when searching
set smartcase           "  `-> except if there is one uppercase character
set incsearch           " show matches as soon as possible
set wrapscan            " searches wrap around the end of the file
set showmatch           " show the matching bracket when inserting
set gdefault            " default substitute g flag

au VimEnter * set hlsearch " highlight last search matches (only on vim startup)
au InsertEnter * setl nohlsearch " hide search highlighting in insert mode
au InsertLeave * setl hlsearch " ... ands re-enable when leaving

" }}}



" {{{ 5. Text editing                                            *vimrc-edition*

set backspace=2         " fix backspace (on some OS/term)
set nostartofline       " leave my cursor position alone!
set foldmethod=manual   " ensure that foldmethod is manual
set virtualedit=block   " allow the cursor to go in to 'invalid' places
set selection=inclusive " cursor is in selection
set scrolloff=8         " keep at least 8 lines after the cursor when scrolling
set sidescrolloff=10    " (same as above about columns during side scrolling)
set textwidth=80        " 80 characters line
set wrap                " wrap long lines
set nolist              " hide invisible characters by default

" spell checker
set spell               " enable spell checking by default
set spelllang=en_us     " configure spell language
set spellfile=~/.vim/spell/en.utf-8.add " additional spell file

" format option stuff (see :help fo-table)
set formatoptions=cro
silent! set formatoptions+=j " not compatible with all vim versions

" remember last position in file (line and column)
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') |
  \ exe 'normal! g`"' | endif

" }}}



" {{{ 6. Indentation / Tabulations                            *vimrc-indent-tab*

set autoindent          " auto-indentation
set smarttab            " insert `shiftwidth` spaces instead of tabs
set expandtab           " replace tabs by spaces
set shiftwidth=2        " n spaces when using <Tab>
set softtabstop=2       " n spaces when using <Tab>
set tabstop=2           " n spaces when using <Tab>

" }}}



" {{{ 7. Errors                                                   *vimrc-errors*

" turn off error bells
set noerrorbells
set visualbell t_vb=

" }}}



" {{{ 8. Binds & Alias                                       *vimrc-binds-alias*

" up and down are more logical with g
nnoremap <silent> j gj
vnoremap <silent> j gj
nnoremap <silent> k gk
vnoremap <silent> k gk

" define leading key
let mapleader = ','

" hide last search matches
nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
vnoremap <silent> <C-L> <C-C>:nohlsearch<CR><C-L>gv

" copy from the cursor to the end of line using Y
nnoremap <silent> Y y$

" keep the cursor in place while joining lines
nnoremap <silent> J mlJ`l

" convenient bind to split line
nnoremap <silent> K i<CR><C-C>^mlgk:silent! s/\ v +$//<CR>:nohlsearch<CR>`l

" disable annoying keys
noremap <silent> <F1> <Nop>
inoremap <silent> <F1> <Nop>
nnoremap <silent> <C-C> <Nop>
noremap <silent> <Del> <Nop>

" useful command line abbreviations
call AbbreviateCommand('tm', 'tabmove')
call AbbreviateCommand('G', 'Git')

" fix command line typos I'm used to do
call AbbreviateCommand('E', 'e')
call AbbreviateCommand('Cd', 'cd')
call AbbreviateCommand('CD', 'cd')
call AbbreviateCommand('Pwd', 'pwd')
call AbbreviateCommand('PWd', 'pwd')
call AbbreviateCommand('PWD', 'pwd')
call AbbreviateCommand('Wq', 'wq')
call AbbreviateCommand('WQ', 'wq')
call AbbreviateCommand('Q', 'q')
call AbbreviateCommand('Qa', 'qa')
call AbbreviateCommand('QA', 'qa')

" center on movements
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
nnoremap <silent> # #zz

" reselect visual block after indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" insert blank lines without entering insert mode
nnoremap <silent> gO O<C-C>0"_D
nnoremap <silent> go o<C-C>0"_D

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

" }}}



" {{{ 9. Languages specific configuration                      *vimrc-languages*

au FileType css        setl shiftwidth=4 softtabstop=4 tabstop=4 iskeyword+=- iskeyword+=# iskeyword+=.
au FileType haskell    setl omnifunc=necoghc#omnifunc shiftwidth=4 softtabstop=4 tabstop=8 shiftround
au FileType html       setl iskeyword+=- iskeyword+=# iskeyword+=.
au FileType javascript setl omnifunc=nodejscomplete#CompleteJS
au FileType make       setl noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
au FileType markdown   setl omnifunc=htmlcomplete#CompleteTags formatoptions=tcroqn2 comments=n:>
au FileType php        setl shiftwidth=4 softtabstop=4 tabstop=4 iskeyword-=$
au FileType python     setl shiftwidth=4 softtabstop=4 tabstop=4

" }}}



" {{{ 10. Plugins                                                *vimrc-plugins*

let g:bundle_dir = resolve(expand('~/.vim/bundle/'))

if has('vim_starting')
  let &rtp .= ',' . g:bundle_dir . '/neobundle.vim/'
endif

call neobundle#begin(g:bundle_dir)
call neobundle#end()


"""""""""""""""""""                                    *vimrc-plugins-neobundle*
" 10.1. NeoBundle "
"""""""""""""""""""

NeoBundleFetch 'Shougo/neobundle.vim', {
  \   'depends': [
  \     [
  \       'Shougo/vimproc.vim', {
  \         'build' : { 'mac' : 'make -f make_mac.mak' },
  \       },
  \     ],
  \   ],
  \   'vim_version': '7.2.051',
  \ }


"""""""""""""""                                            *vimrc-plugins-theme*
" 10.2. Theme "
"""""""""""""""

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


"""""""""""""""""""                                    *vimrc-plugins-languages*
" 10.3. Languages "
"""""""""""""""""""

" --- Generic

NeoBundle 'editorconfig/editorconfig-vim'

" --- C/CPP

NeoBundle 'google.vim'

" --- CoffeeScript

NeoBundle 'kchmck/vim-coffee-script'

" --- CSS

NeoBundle 'ap/vim-css-color'

" --- Docker

NeoBundle 'ekalinin/Dockerfile.vim'

" --- Git

NeoBundle 'tpope/vim-git'

" --- Haskell

let g:necoghc_enable_detailed_browse = 1
NeoBundle 'eagletmt/neco-ghc'

" --- HTML

NeoBundle 'othree/html5.vim'

" --- Jade

NeoBundle 'digitaltoad/vim-jade'

" --- Javascript

let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting
NeoBundle 'pangloss/vim-javascript'

NeoBundle 'mxw/vim-jsx'

NeoBundle 'jelera/vim-javascript-syntax'

NeoBundle 'marijnh/tern_for_vim', {
  \   'build': { 'mac': 'npm install' }
  \ }

let g:nodejs_complete_config = { 'js_compl_fn': 'tern#Complete' }
NeoBundle 'myhere/vim-nodejs-complete'

" --- JSON

NeoBundle 'elzr/vim-json'

" --- LESS

NeoBundle 'groenewege/vim-less'

" --- Markdown

NeoBundle 'tpope/vim-markdown'

" --- Nginx

NeoBundle 'nginx.vim'
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/*,*nginx.conf if &ft == '' | setfiletype nginx | endif

" --- SASS/SCSS

NeoBundle 'cakebaker/scss-syntax.vim'

" --- Stylus

NeoBundle 'wavded/vim-stylus'

" ---

NeoBundle 'matchit.zip'

"""""""""""""""                                            *vimrc-plugins-tools*
" 10.4. Tools "
"""""""""""""""

NeoBundle 'airblade/vim-rooter'
NeoBundle 'bronson/vim-visual-star-search'
NeoBundle 'godlygeek/tabular'
NeoBundle 'rizzatti/dash.vim'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'tpope/vim-abolish'
NeoBundle 'tpope/vim-eunuch'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-repeat'
NeoBundle 'tpope/vim-surround'
NeoBundle 'tpope/vim-unimpaired'

" ---  Tagbar
let g:tagbar_autoclose = 1
NeoBundle 'majutsushi/tagbar', {
  \   'external_commands': ['ctags'],
  \ }
let bundle = neobundle#get('tagbar')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>t :TagbarToggle<CR>
endfunction

" --- Winresizer
let g:winresizer_start_key = '<C-W><C-W>'
NeoBundle 'jimsei/winresizer'

" --- Syntastic
let g:syntastic_check_on_open = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 2
let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_mode_map = {
  \   'mode': 'passive',
  \   'active_filetypes': ['javascript'],
  \   'passive_filetypes': []
  \ }
NeoBundle 'scrooloose/syntastic', {
  \   'build': { 'mac': 'npm install -g jshint' }
  \ }
let bundle = neobundle#get('syntastic')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>s :SyntasticCheck<CR>
endfunction

" --- YouCompleteMe
let g:ycm_complete_in_comments = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_seed_identifiers_with_syntax = 1
set completeopt=longest,menuone
let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-P>', '<Up>']
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
NeoBundle 'Valloric/YouCompleteMe', {
  \   'build': { 'mac': 'git submodule update --init --recursive && ./install.sh --clang-completer' },
  \   'vim_version': '7.3.584',
  \ }
let bundle = neobundle#get('YouCompleteMe')

" --- UltiSnips
let g:UltiSnipsSnippetDirectories = ['snippet']
let g:UltiSnipsExpandTrigger = '<C-J>'
let g:UltiSnipsJumpForwardTrigger = '<C-J>'
let g:UltiSnipsJumpBackwardTrigger = '<C-K>'
NeoBundle 'SirVer/ultisnips'

" --- CtrlP
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
let g:ctrlp_mruf_case_sensitive = IsLinuxBSD() ? 1 : 0 " set case sensitive search
let g:ctrlp_mruf_save_on_update = 0 " only save on Vim exit
NeoBundle 'kien/ctrlp.vim'
let bundle = neobundle#get('ctrlp.vim')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>b :CtrlPBuffer<CR>
endfunction

" --- Session
let g:session_directory = '~/.vim/tmp/sessions//' " where to store the sessions
let g:session_default_overwrite = 1 " overwrite last default session
let g:session_autoload = 'no' " do not autoload sessions
let g:session_autosave = 'yes' " automatically save session on vim close
let g:session_command_aliases = 1 " enable aliased commands
set sessionoptions-=folds   " do not store folds in session file
set sessionoptions-=help    " do not store help windows in session file
set sessionoptions-=options " do not store options in session file
NeoBundle 'xolox/vim-session', {
  \     'depends': [
  \         'xolox/vim-misc'
  \     ],
  \ }
au VimEnter * call CreateDirectory(g:session_directory)

" --- Airline
let g:airline_theme = 'badwolf' " specify theme
let g:airline_exclude_preview = 1 " remove airline from preview window
let g:airline_left_sep = '»' " change left sections separator
let g:airline_right_sep = '«' " change right sections separator
let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
let g:airline_powerline_fonts = 0 " explicitly disable powerline fonts support
NeoBundle 'bling/vim-airline', {
  \     'vim_version': '7.2',
  \ }
let bundle = neobundle#get('vim-airline')
function! bundle.hooks.on_post_source(bundle)
  set noshowmode " hide the duplicate mode in bottom status bar
endfunction


" Install bundles && generate/check documentation
NeoBundleCheck

" }}}



" {{{ 11. File type / Syntax detection                          *vimrc-filetype*

syntax enable
filetype plugin indent on

" }}}



" Call NeoBundle post source hooks again to support several consecutive
" `source ~/.vimrc`
call neobundle#call_hook('on_post_source')

" Avoid ~/.{vimrc,exrc} modification by autocmd, shell and write
set secure



"vim:isk+=-:isk+=*
