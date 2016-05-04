" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

if !1 | finish | endif " Skip initialization for vim-tiny or vim-small

if &compatible | set nocompatible | endif " 21st century

syntax enable
filetype plugin indent on

let mapleader = ' '
let b:vim_directory = expand('~/.vim')
let b:bundle_directory = b:vim_directory . '/bundle'
let b:tmp_directory = b:vim_directory . '/tmp'

" Plugins

  call plug#begin(b:bundle_directory)

    " Theme

      Plug 'tomasr/molokai'

    " UI/UX

      Plug 'Lokaltog/vim-easymotion', { 'on': [ '<Plug>(easymotion-s)' ] }
        nmap <silent> S <Plug>(easymotion-s)
        xmap <silent> S <Plug>(easymotion-s)
        omap <silent> S <Plug>(easymotion-s)
        let g:EasyMotion_do_mapping = 1 " disable the default mappings
        let g:EasyMotion_keys = 'LPUFYW;QNTESIROA' " Colemak toprow/homerow
        let g:EasyMotion_off_screen_search = 1 " do not search outside of screen
        let g:EasyMotion_smartcase = 1 " like Vim
        let g:EasyMotion_use_smartsign_us = 1 " ! and 1 are treated as the same
        let g:EasyMotion_use_upper = 1 " recognize both upper and lowercase keys

      Plug 'SirVer/ultisnips'
        let g:UltiSnipsExpandTrigger = '<Tab>'
        let g:UltiSnipsJumpForwardTrigger = '<Tab>'
        let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
        let g:UltiSnipsSnippetDirectories = [ 'snippet' ]

      Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --tern-completer' }
        let g:ycm_collect_identifiers_from_comments_and_strings = 0
        let g:ycm_collect_identifiers_from_tags_files = 0
        let g:ycm_complete_in_comments = 1
        let g:ycm_key_list_previous_completion = [ '<C-p>', '<Up>' ]
        let g:ycm_key_list_select_completion = [ '<C-n>', '<Down>' ]
        let g:ycm_seed_identifiers_with_syntax = 1
        set completeopt=longest,menuone

      Plug 'editorconfig/editorconfig-vim'

      Plug 'scrooloose/nerdcommenter'
        nmap <silent> <leader>c <Plug>NERDCommenterToggle
        xmap <silent> <leader>c <Plug>NERDCommenterToggle
        let g:NERDCreateDefaultMappings = 0
        let g:NERDCommentWholeLinesInVMode = 1
        let g:NERDMenuMode = 0
        let g:NERDSpaceDelims = 1

      Plug 'tpope/vim-abolish'

      Plug 'tpope/vim-eunuch'

      Plug 'tpope/vim-fugitive'

      Plug 'tpope/vim-repeat'

      Plug 'tpope/vim-surround', { 'on': [ '<Plug>Csurround', '<Plug>Dsurround' ] }
        nmap <silent> cs <Plug>Csurround
        nmap <silent> ds <Plug>Dsurround
        let g:surround_no_mappings = 1 " disable the default mappings
        let g:surround_indent = 1 " reindent with `=` after surrounding

      Plug 'tpope/vim-unimpaired'

      Plug 'vim-airline/vim-airline-themes' | Plug 'vim-airline/vim-airline'
        let g:airline#extensions#disable_rtp_load = 1
        let g:airline_extensions = [ 'branch', 'tabline', 'whitespace', 'ycm' ]
        let g:airline_exclude_preview = 1 " remove airline from preview window
        let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
        let g:airline_theme = 'wombat'
        let g:airline_powerline_fonts = 1
        set noshowmode " hide the duplicate mode in bottom status bar

      Plug 'simeji/winresizer'
        let g:winresizer_start_key = '<C-W><C-W>'

      Plug 'airblade/vim-gitgutter'
        nmap [c <Plug>GitGutterPrevHunk
        nmap ]c <Plug>GitGutterNextHunk
        let g:gitgutter_map_keys = 0

      Plug 'scrooloose/nerdtree'
        nnoremap <silent> <Leader>f :<C-u>NERDTreeToggle<CR>
        let g:NERDTreeShowHidden = 1
        let g:NERDTreeWinSize = 35
        let g:NERDTreeMinimalUI = 1
        let g:NERDTreeAutoDeleteBuffer = 1
        let g:NERDTreeMouseMode = 3
        autocmd FileType nerdtree call s:on_nerdtree_buffer()
        function! s:on_nerdtree_buffer()
          nnoremap <silent><buffer> <Esc> :<C-u>NERDTreeClose<CR>
        endfunction

      Plug 'majutsushi/tagbar'
        nnoremap <silent> <Leader>t :<C-u>TagbarToggle<CR>
        let g:tagbar_width = 35
        let g:tagbar_compact = 1
        let g:tagbar_singleclick = 1
        let g:tagbar_autofocus = 1
        autocmd FileType tagbar call s:on_tagbar_buffer()
        function! s:on_tagbar_buffer()
          nnoremap <silent><buffer> <Esc> :<C-u>TagbarClose<CR>
        endfunction

      Plug 'Shougo/vimproc.vim', { 'do': 'make' } | Plug 'Shougo/unite.vim'
        nnoremap <silent> <C-p> :<C-u>Unite -buffer-name=files -auto-preview -vertical-preview -no-split buffer file_rec/git<CR>
        nnoremap <silent> <C-n> :<C-u>Unite -buffer-name=shell -direction=botright menu:shell<CR>
        let g:unite_enable_auto_select = 0
        let g:unite_source_menu_menus = get(g:, 'unite_source_menu_menus', {})
        let g:unite_source_menu_menus.shell = {
        \   'command_candidates': [
        \     [ 'git status', 'Gstatus' ],
        \   ]
        \ }
        autocmd FileType unite call s:on_unite_buffer()
        function! s:on_unite_buffer()
          silent! GitGutterDisable
          imap <silent><buffer> <Esc> i_<Plug>(unite_exit)
        endfunction

    " Languages

      Plug 'docker/docker', { 'for': [ 'docker' ], 'rtp': 'contrib/syntax/vim' }

      Plug 'fatih/vim-go', { 'for': [ 'go' ], 'do': 'go get -u github.com/jstemmer/gotags github.com/nsf/gocode' }

      Plug 'moll/vim-node', { 'for': [ 'javascript' ] }

      Plug 'pangloss/vim-javascript', { 'for': [ 'javascript' ] }
        let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting

      Plug 'elzr/vim-json', { 'for': [ 'json' ] }

      Plug 'plasticboy/vim-markdown', { 'for': [ 'markdown' ] }
        let g:vim_markdown_folding_disabled = 1

  call plug#end()

  " 'Shougo/unite.vim' (function calls -> has to happen after plugin's been loaded)
    call unite#custom#profile('default', 'context', { 'silent': 1, 'start_insert': 1, 'unique': 1, 'wipe': 1 })
    call unite#custom#source('buffer,file_rec/git', 'ignore_pattern', 'bower_components/\|coverage/\|docs/\|node_modules/')
    call unite#filters#matcher_default#use([ 'matcher_fuzzy' ])

" Inlined plugins

  " highlight search matches (except while being in insert mode)
  au VimEnter * set hlsearch
  au InsertEnter * setl nohlsearch
  au InsertLeave * setl hlsearch

  " highlight cursor line (except while being in insert mode)
  au VimEnter * set cursorline
  au InsertEnter * setl nocursorline
  au InsertLeave * setl cursorline

  " remember last position in file (line and column)
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute 'normal! g`"' | endif

  " automatically remove trailing whitespace when saving
  au BufWritePre * :%s/\s\+$//e

" Enhanced mappings

  " better `j` and `k`
  nnoremap <silent> j gj
  vnoremap <silent> j gj
  nnoremap <silent> k gk
  vnoremap <silent> k gk

  " copy from the cursor to the end of line using Y (matches D behavior)
  nnoremap <silent> Y y$

  " keep the cursor in place while joining lines (uses the Z register)
  nnoremap <silent> J mZJ`Z

  " disable annoying mappings
  noremap <silent> <F1>   <Nop>
  noremap <silent> <C-w>f <Nop>
  noremap <silent> <Del>  <Nop>
  noremap <silent> q:     <Nop>

  " reselect visual block after indent
  vnoremap <silent> < <gv
  vnoremap <silent> > >gv

  " fix how ^E and ^Y behave in insert mode
  inoremap <silent><expr> <C-e> pumvisible() ? "\<C-y>\<C-e>" : "\<C-e>"
  inoremap <silent><expr> <C-y> pumvisible() ? "\<C-y>\<C-y>" : "\<C-y>"

  " clean screen and reload file
  nnoremap <silent> <C-l>      :<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-l>
  xnoremap <silent> <C-l> <C-c>:<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-l>gv

" Settings

  " encoding
  set encoding=utf-8 " ensure proper encoding
  set fileencodings=utf-8 " ensure proper encoding

  " indentation
  set autoindent " auto-indentation
  set backspace=2 " fix backspace (on some OS/terminals)
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
  set wildignore+=*/.git/*,*/.hg/*,*/.svn/* " ignore SCM
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
  set showtabline=2 " always show tabbar

  " vim
  let g:netrw_dirhistmax = 0 " disable netrw
  let &viminfo = &viminfo + ',n' . b:tmp_directory . '/info//' " change viminfo file path
  set nobackup " disable backup files
  set noswapfile " disable swap files

  " theme configuration
  set background=dark
  set colorcolumn=+1 " relative to text-width
  colorscheme molokai

  " mouse
  if has('mouse')
    set mouse=a
  endif

  " persistent undo
  if has('persistent_undo')
    set undofile
    set undolevels=1000
    set undoreload=10000
    let &undodir = b:tmp_directory . '/undo//'
  endif

  " spell checking
  if has('spell')
    set spell
  endif

  " Avoid configuration files modification by autocmd, shell and write
  set secure

" GUI settings

  " MacVim (https://github.com/macvim-dev/macvim)
  " - disable antialiasing with `!defaults write org.vim.MacVim AppleFontSmoothing -int 0`
  if has('gui_macvim')
    " Make Command+W delete the current buffer
    macmenu File.Close key=<nop>
    nnoremap <silent> <D-w> :bdelete<CR>
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

  " Neovim.app (https://github.com/neovim/neovim)
  " - disable antialiasing with `!defaults write uk.foon.Neovim AppleFontSmoothing -int 0`
  if exists('neovim_dot_app')
    " Make Command+W delete the current buffer
    call MacMenu('Window.Close Tab', '')
    nnoremap <silent> <D-w> :bdelete<CR>
    " Set the font
    silent! call MacSetFont('Monaco', '13') " fallback
    silent! call MacSetFont('Hack', '13') " preferred
  endif
