" Author: Aymeric Beaumet <hi@aymericbeaumet.com>>
" Github: @aymericbeaumet/dotfiles

" requirements {{{

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
    " highlight cursor line (except while being in insert mode)
    autocmd VimEnter,BufReadPost,InsertLeave * setl cursorline
    autocmd InsertEnter * setl nocursorline
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

  " }}}

  " plugins > interface {{{

    Plug 'altercation/vim-colors-solarized'

    Plug 'mhinz/vim-startify'
      nnoremap <silent> <Leader>Ss :<C-u>SSave<CR>
      nnoremap <silent> <Leader>Sq :<C-u>SClose<CR>
      let g:startify_bookmarks = [
      \   '~/.gitconfig',
      \   '~/.vimrc',
      \   '~/.tmux.conf',
      \   '~/.zshrc',
      \ ]
      let g:startify_commands = [
      \   [ '[vim] clean plugins', 'PlugClean' ],
      \   [ '[vim] install plugins', 'PlugInstall | UpdateRemotePlugins' ],
      \   [ '[vim] update plugins', 'PlugUpdate | UpdateRemotePlugins' ],
      \ ]
      let g:startify_session_dir = expand('~/.vim/tmp/sessions')
      let g:startify_session_persistence = 1
      let g:startify_session_delete_buffers = 1
      let g:startify_change_to_dir = 0
      let g:startify_change_to_vcs_root = 0
      augroup vimrc_startify
        autocmd!
        autocmd VimEnter * if !argc() || (argc() == 1 && isdirectory(argv(0))) | Startify | NERDTree | wincmd w | endif
      augroup END

    Plug 'vim-airline/vim-airline-themes' | Plug 'vim-airline/vim-airline'
      set noshowmode " hide the duplicate mode in bottom status bar
      let g:airline_theme = 'solarized'
      let g:airline_powerline_fonts = 1
      let g:airline_extensions = [
      \   'branch',
      \   'hunks',
      \   'neomake',
      \   'promptline',
      \   'tmuxline',
      \   'whitespace',
      \ ]
      let g:airline#extensions#promptline#snapshot_file = '~/.zsh/status.sh'
      let g:airline#extensions#tabline#show_tab_type = 0
      let g:airline#extensions#tabline#buffer_min_count = 0
      let g:airline#extensions#tabline#exclude_preview = 1
      let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
      let g:airline#extensions#tabline#show_buffers = 1
      let g:airline#extensions#tabline#show_tabs = 0
      let g:airline#extensions#tmuxline#snapshot_file = '~/.tmux/status.conf'
      function! AirlineInit()
        let g:airline_section_a = airline#section#create_left([
        \   '%{simplify(expand("%:~"))}',
        \ ])
        let g:airline_section_b = airline#section#create_left([
        \   'branch',
        \   'hunks',
        \ ])
        let g:airline_section_c = airline#section#create_left([
        \ ])
        let g:airline_section_x = airline#section#create_right([
        \   '%{&filetype}',
        \ ])
        let g:airline_section_y = airline#section#create_right([
        \   '%{&fileencoding}',
        \   '%{&fileformat}',
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
        autocmd User AirlineAfterInit call AirlineInit()
      augroup END

    Plug 'airblade/vim-gitgutter'
      nmap [c <Plug>GitGutterPrevHunk
      nmap ]c <Plug>GitGutterNextHunk
      let g:gitgutter_map_keys = 0
      let g:gitgutter_git_executable = 'git'

    Plug 'scrooloose/nerdtree'
      nnoremap <silent> <Leader>t :<C-u>NERDTreeToggle<CR>
      let g:NERDTreeWinSize = 35
      let g:NERDTreeMinimalUI = 1
      let g:NERDTreeShowHidden = 1
      let g:NERDTreeMouseMode = 3
      let g:NERDTreeCascadeSingleChildDir = 1
      let g:NERDTreeCascadeOpenSingleChildDir = 1
      let g:NERDTreeAutoDeleteBuffer = 1
      let g:NERDTreeDirArrowExpandable = ''
      let g:NERDTreeDirArrowCollapsible = ''
      let g:NERDTreeIgnore = [
      \   '\.git$[[dir]]',
      \   '\.gitmodules$[[file]]',
      \   'node_modules$[[dir]]',
      \ ]
      augroup vimrc_nerdtree
        autocmd!
        autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
      augroup END

  " }}}

  " plugins > tmux {{{

    Plug 'benmills/vimux'
      nnoremap <silent> <Leader>r: :<C-u>call VimuxPromptCommand()<CR>
      nnoremap <silent> <Leader>rd :<C-u>call VimuxRunCommand('clear ; npm run dev')<CR>
      nnoremap <silent> <Leader>ri :<C-u>call VimuxRunCommand('clear ; npm install')<CR>
      nnoremap <silent> <Leader>rl :<C-u>call VimuxRunLastCommand<CR>
      nnoremap <silent> <Leader>rt :<C-u>call VimuxRunCommand('clear ; npm test')<CR>

    Plug 'edkolev/tmuxline.vim'
      let g:tmuxline_powerline_separators = 1
      let g:tmuxline_preset = {
      \   'a': [
      \     '#h',
      \   ],
      \   'b': [
      \     '#(whoami)',
      \   ],
      \   'c': [
      \     '#S',
      \   ],
      \   'win': [
      \     '#I',
      \     '#W',
      \   ],
      \   'cwin': [
      \     '#I',
      \     '#W',
      \   ],
      \   'x': [
      \     "#(ansiweather -w false -h false -p false -d false -s true -a false -l Paris,FR | awk '" . '{ print $6 $7 " (" $4 ")" }' . "')",
      \   ],
      \   'y': [
      \     "#(m battery status | awk -F '[;[:space:]]' '" . '/InternalBattery/ { print $4 " (" toupper(substr($6,1,1)) substr($6,2) ")" }' . "')",
      \   ],
      \   'z': [
      \     '#(date "+%a %-d, %H:%M")',
      \   ],
      \   'options': {
      \     'status-position': 'top',
      \     'status-justify': 'centre',
      \   },
      \ }

  " }}}

  " plugins > zsh {{{

    Plug 'edkolev/promptline.vim'
      let g:promptline_powerline_symbols = 1
      function! PromptlineInit()
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
      endfunction
      augroup vimrc_promptline
        autocmd!
        autocmd VimEnter * call PromptlineInit()
      augroup END

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

    Plug 'tpope/vim-repeat'

    Plug 'tpope/vim-surround'
      nmap <silent> cs <Plug>Csurround
      nmap <silent> ds <Plug>Dsurround
      let g:surround_no_mappings = 1 " disable the default mappings
      let g:surround_indent = 1 " reindent with `=` after surrounding

    Plug 'tpope/vim-unimpaired'

    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
      command! -bang -nargs=* GGrep call fzf#vim#grep('git grep --line-number ' . shellescape(<q-args>), 0, <bang>0)
      nnoremap <silent> <Leader>b :<C-u>Buffers<CR>
      nnoremap <silent> <Leader>f :<C-u>Files<CR>
      nnoremap <silent> <Leader>F :<C-u>GFiles<CR>
      nnoremap <silent> <Leader>g :<C-u>Ag<CR>
      nnoremap <silent> <Leader>G :<C-u>GGrep<CR>
      let g:fzf_action = {
      \   'ctrl-s': 'split',
      \   'ctrl-v': 'vsplit',
      \ }
      let g:fzf_layout = {
      \   'down': '~40%',
      \ }
      function! s:CommandHistory()
        let s:INTERRUPT_CODE = "\u03\u0c" " <C-c><C-l>
        let s:ENTER_CODE = "\u0d" " <C-m>
        let s:cmdtype = getcmdtype()
        let s:args = string({
        \   "options": "--query=" . shellescape(getcmdline()),
        \ })
        if s:cmdtype == ':'
          return s:INTERRUPT_CODE . ":keepp call fzf#vim#command_history(" .  s:args . ")" . s:ENTER_CODE
        elseif s:cmdtype == '/'
          return s:INTERRUPT_CODE . ":keepp call fzf#vim#search_history(" .  s:args . ")" . s:ENTER_CODE
        else
          return ''
        endif
      endfunction
      cnoremap <expr> <C-r> <SID>CommandHistory()

  " }}}

  " plugins > code {{{

    Plug 'benekastah/neomake', { 'do': '
    \   npm install --global eslint standard xo;
    \   npm install --global jsonlint;
    \ ' }
      let g:neomake_javascript_enabled_makers = [ 'eslint' ]
      let g:neomake_json_enabled_makers = [ 'jsonlint' ]
      augroup vimrc_neomake
        autocmd!
        autocmd BufReadPost,BufWritePost * Neomake
      augroup END

    Plug 'Shougo/neosnippet.vim'
      let g:neosnippet#disable_runtime_snippets = { '_' : 1 }
      let g:neosnippet#snippets_directory = expand('~/.vim/snippets')
      if has('conceal') | set conceallevel=2 concealcursor=niv | endif

    if has('nvim') && has('python3')
      Plug 'Shougo/deoplete.nvim', { 'do': '
      \    pip2 install --upgrade neovim;
      \    pip3 install --upgrade neovim;
      \ ' }
        let g:deoplete#enable_at_startup = 1
        let g:deoplete#max_abbr_width = 0
        let g:deoplete#max_menu_width = 0
        let g:deoplete#file#enable_buffer_path = 1
        set completeopt=menuone,noinsert
        " Remap tab to perform the following actions in order of priority:
        " - insert the snippet if recognized
        " - insert the completion if the pum is visible
        " - jump to the snippet placeholder
        " - insert a tab
        imap <silent><expr> <TAB>
        \ neosnippet#expandable() ?
        \   "\<Plug>(neosnippet_expand)" :
        \ pumvisible() ?
        \   "\<C-y>" :
        \ neosnippet#jumpable() ?
        \   "\<Plug>(neosnippet_jump)" :
        \   "\<TAB>"
        " Make Enter close the pum first (if any) before inserting a new line
        imap <silent><expr> <CR>
        \ pumvisible() ?
        \   "\<C-e><CR>" :
        \   "\<CR>"
    endif

    " javascript
    Plug 'pangloss/vim-javascript'
    Plug 'carlitux/deoplete-ternjs', { 'do': '
    \   npm install --global tern;
    \ ' }

    " json
    Plug 'elzr/vim-json'

    " markdown
    Plug 'gabrielelana/vim-markdown'

    " vimscript
    Plug 'Shougo/neco-vim'
    Plug 'Shougo/neco-syntax'

  " }}}

  call plug#end()

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
set shiftwidth=2 " n spaces when using <TAB>
set smarttab " insert `shiftwidth` spaces instead of tabs
set softtabstop=2 " n spaces when using <TAB>
set tabstop=2 " n spaces when using <TAB>

" interface
let g:netrw_dirhistmax = 0 " disable netrw
set colorcolumn=+1 " relative to text-width
set fillchars="" " remove split separators
silent! set formatoptions=croqj " format option stuff (see :help fo-table)
set laststatus=2 " always display status line
set list " show invisible characters
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

  " [R]eload configuration
  nnoremap <silent> <Leader>R  :<C-u>source $MYVIMRC<CR>:echom 'Vim configuration reloaded!'<CR>

" }}}

" modeline
set modeline " enable modelines for per file configuration
set modelines=1 " consider the first/last lines

" mouse
if has('mouse')
  set mouse=a
  if exists('&ttyscroll') | set ttyscroll=3 | endif
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
set viminfo=%,<800,'10,/50,:100,h,f0,n~/.vim/tmp/viminfo
set nobackup " disable backup files
set noswapfile " disable swap files
set secure " protect the configuration files

" MacVim (https://github.com/macvim-dev/macvim) {{{
if has('gui_macvim')
  " Disable antialiasing with `!defaults write org.vim.MacVim AppleFontSmoothing -int 0`
  " Set the font
  silent! set guifont=Monaco:h13 " fallback
  silent! set guifont=Hack:h13 " preferred
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
  silent! call MacSetFont('Monaco', 13) " fallback
  silent! call MacSetFont('Hack', 13) " preferred
  " Enable anti-aliasing (see above to disable the ugly AA from OSX)
  call MacSetFontShouldAntialias(1)
endif
" }}}
