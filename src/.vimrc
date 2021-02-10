" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
" Github: @aymericbeaumet/dotfiles

" init {{{

  filetype plugin indent on
  syntax on
  if has('vim_starting') | set encoding=UTF-8 | endif
  set fileencodings=utf-8
  scriptencoding utf-8
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" autocmd {{{

augroup vimrc

  " custom mappings for some filetypes
  autocmd FileType python,rust,go,javascript,javascriptreact,typescript,typescriptreact nnoremap <silent> <buffer> <C-]> :ALEGoToDefinition<CR>
  autocmd FileType python,rust,go,javascript,javascriptreact,typescript,typescriptreact nnoremap <silent> <buffer> K :ALEHover<CR>

  " syntax highlighting for custom filetypes
  autocmd BufNewFile,BufRead *.tpl set ft=yaml

  " wrap at 80 characters for markdown
  autocmd BufRead,BufNewFile *.md setlocal textwidth=80

augroup END

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))

    Plug 'git@github.com:aymericbeaumet/vim-symlink.git' | Plug 'moll/vim-bbye'
    Plug 'git@github.com:aymericbeaumet/vim-zshmappings.git'
      let g:zshmappings_command_mode_search_history_tool = 'fzf.vim'

    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
    Plug 'Valloric/ListToggle'
    Plug 'alvan/vim-closetag'
    Plug 'arcticicestudio/nord-vim'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'jiangmiao/auto-pairs'
    Plug 'puremourning/vimspector'
    Plug 'scrooloose/nerdcommenter'
    Plug 'tpope/vim-abolish'
    Plug 'tpope/vim-eunuch'
    Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-unimpaired'

    Plug 'airblade/vim-rooter'
      let g:rooter_patterns = ['.git']
      let g:rooter_cd_cmd = 'lcd'
      let g:rooter_silent_chdir = 1
      let g:rooter_resolve_links = 1

    Plug 'embear/vim-localvimrc'
      let g:localvimrc_persistent = 1

    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_keys = 'X.Z/C,VMBKQ;WYFUPLAORISETN'
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_use_upper = 1

    Plug 'dense-analysis/ale'
      let g:ale_completion_enabled = 1
      let g:ale_completion_autoimport = 1
      set omnifunc=ale#completion#OmniFunc
      set completeopt=menu,menuone,noinsert,noselect
      let g:ale_fix_on_save = 1
      let g:ale_lint_on_save = 1
      let g:ale_linters_explicit = 1
      let g:ale_lsp_show_message_severity = 'warning'
      let g:ale_sign_error = 'E'
      let g:ale_sign_info = 'I'
      let g:ale_sign_warning = 'W'
      let g:ale_fixers = {
            \   '*': ['remove_trailing_lines', 'trim_whitespace'],
            \   'go': ['goimports', 'gofmt'],
            \   'graphql': ['prettier'],
            \   'javascript': ['prettier'],
            \   'javascriptreact': ['prettier'],
            \   'python': ['black'],
            \   'rust': ['rustfmt'],
            \   'terraform': ['terraform'],
            \   'typescript': ['prettier'],
            \   'typescriptreact': ['prettier'],
            \ }
      let g:ale_linters = {
            \   'go': ['gopls', 'golangci-lint', 'revive'],
            \   'javascript': ['tsserver'],
            \   'javascriptreact': ['tsserver'],
            \   'python': ['pyls', 'blake', 'flake8'],
            \   'rust': ['analyzer'],
            \   'sh': ['shellcheck'],
            \   'terraform': ['terraform', 'tflint'],
            \   'typescript': ['tsserver'],
            \   'typescriptreact': ['tsserver'],
            \   'vim': ['vint'],
            \   'sql': ['sqlint'],
            \   'zsh': ['shellcheck'],
            \ }
      let g:ale_go_gofmt_options = '-s'
      let g:ale_go_golangci_lint_options = '--disable wsl'
      let g:ale_go_golangci_lint_package = 1
      let g:ale_python_auto_pipenv = 1

    Plug 'lifepillar/pgsql.vim'
    Plug 'HerringtonDarkholme/yats.vim'
    Plug 'hashivim/vim-terraform'
    Plug 'rust-lang/rust.vim'
    Plug 'zchee/vim-flatbuffers'
    Plug 'jparise/vim-graphql'
    Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
    Plug 'neoclide/jsonc.vim'

  call plug#end()

" }}}

" commands {{{
  command! -bang -nargs=? -complete=dir FilesWithPreview
        \ call fzf#vim#files(
        \   <q-args>,
        \   fzf#vim#with_preview({'source': 'fd --type file --hidden --exclude .git -E "*.qtpl.go"'}),
        \   <bang>0,
        \ )

  function! Ripgrep(query, fullscreen)
    let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    let initial_command = printf(command_fmt, shellescape(a:query))
    let reload_command = printf(command_fmt, '{q}')
    let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command, '--delimiter=:', '--nth=4..']}
    call fzf#vim#grep(initial_command, 1, spec, a:fullscreen)
  endfunction
  command! -nargs=* -bang Ripgrep call Ripgrep(<q-args>, <bang>0)

  " https://vi.stackexchange.com/a/8535/1956
  command! Cnext try | cnext | catch | silent! cfirst | endtry
  command! Cprev try | cprev | catch | silent! clast  | endtry
  command! Lnext try | lnext | catch | silent! lfirst | endtry
  command! Lprev try | lprev | catch | silent! llast  | endtry

  cnoreabbrev Remove Delete

" }}}

" mappings {{{

  set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
  set ttimeoutlen=0  " instant insert mode exit using escape

  vnoremap <silent> <Leader>s :sort<CR>
  vnoremap <silent> <CR> :<C-U>'<,'>w !squeeze -1 --url --open<CR><CR>

  nnoremap <silent> [q :Cprev<CR>
  nnoremap <silent> ]q :Cnext<CR>
  nnoremap <silent> [l :Lprev<CR>
  nnoremap <silent> ]l :Lnext<CR>

  nnoremap <silent> <Leader>/ :BLines<CR>
  nnoremap <silent> <Leader>b :Buffers<CR>
  " <Leader>c NerdCommenter leader
  nnoremap <silent> <Leader>d :Bwipeout<CR>
  nnoremap <silent> <Leader>e :Explore<CR>
  nnoremap <silent> <Leader>f :FilesWithPreview<CR>
  " <Leader>g git commands leader (see below)
  " <Leader>l LToggle
  " <Leader>q QToggle
  nnoremap <silent> <Leader>r :Ripgrep<CR>
  " <Leader>v vimrc commands leader (see below)

  nnoremap <silent> <Leader>gb       :Gblame<CR>
  nnoremap <silent> <Leader>gd       :Gvdiffsplit<CR>
  nnoremap <silent> <Leader>gl       :Commits<CR>
  nnoremap <silent> <Leader>gm       :Git mergetool<CR>
  nnoremap <silent> <Leader>gw       :Gwrite<CR>
  nnoremap <silent> <Leader>g<Space> :G<Space>

  nnoremap <silent> <Leader>ve :edit ~/.vimrc<CR>
  nnoremap <silent> <Leader>vs :source ~/.vimrc<CR>
  nnoremap <silent> <Leader>vu :PlugUpdate<CR>
  nnoremap <silent> <Leader>vU :PlugUpdate!<CR>

  " sorry
  inoremap <C-Space> <Nop>
  nnoremap <Space> <Nop>
  nnoremap Q <Nop>

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

  " keep the next/previous in the middle of the screen
  nnoremap <silent> n nzz
  nnoremap <silent> N Nzz

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
set nocursorline " do not color the cursorline

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
colorscheme nord
set fillchars="" " remove split separators
set laststatus=2 " always display status line
set nospell " disable spell checking
set shortmess=aoOsIctF " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set mouse=a " enable mouse support
set noshowmode " hide mode from status bar
set noinsertmode

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
