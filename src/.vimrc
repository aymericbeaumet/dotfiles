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

  " custom mappings in go/rust buffers
  "autocmd FileType go,rust nnoremap <silent> <buffer> <C-[> :ALEFindReferences<CR>
  autocmd FileType go,rust nnoremap <silent> <buffer> <C-]> :ALEGoToDefinition<CR>
  autocmd FileType go,rust nnoremap <silent> <buffer> K :ALEHover<CR>

  " syntax highlighting for custom filetypes
  autocmd BufNewFile,BufRead *.tpl set ft=yaml

augroup END

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))

    Plug 'arcticicestudio/nord-vim'
    Plug 'airblade/vim-rooter'
    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb' | Plug 'shumphrey/fugitive-gitlab.vim'
    Plug 'moll/vim-bbye' | Plug 'aymericbeaumet/vim-symlink'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-speeddating'
    Plug 'tpope/vim-eunuch'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Valloric/ListToggle'

    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_keys = 'X.Z/C,VMBKQ;WYFUPLAORISETN'
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_use_upper = 1

    Plug 'dense-analysis/ale', { 'do': '~/.dotfiles/make tools' }
      let g:ale_fix_on_save = 1
      let g:ale_lint_on_save = 1
      let g:ale_lint_on_insert_leave = 0
      let g:ale_lint_on_text_changed = 0
      let g:ale_linters_explicit = 1
      let g:ale_fixers = {
            \   'terraform': ['terraform'],
            \   'rust': ['rustfmt'],
            \   'go': ['goimports', 'gofmt'],
            \   '*': ['remove_trailing_lines', 'trim_whitespace'],
            \ }
      let g:ale_linters = {
            \   'terraform': ['terraform', 'tflint'],
            \   'rust': ['rls'],
            \   'go': ['gopls', 'golangci-lint'],
            \ }
      let g:ale_type_map = {
            \   'golangci-lint': {'ES': 'WS', 'E': 'W'},
            \ }
      let g:ale_go_gofmt_options = '-s'
      let g:ale_lsp_show_message_severity = 'warning'
      let g:ale_sign_error = 'E'
      let g:ale_sign_warning = 'W'
      let g:ale_sign_info = 'I'
      let g:ale_set_highlights = 0
      let g:ale_completion_enabled = 1
      set omnifunc=ale#completion#OmniFunc
      set completeopt=menu,menuone,noinsert,noselect

    Plug 'hashivim/vim-terraform'

    Plug 'rust-lang/rust.vim'

    "Plug 'fatih/vim-go'

    Plug 'elixir-editors/vim-elixir'

    Plug 'MaxMEllon/vim-jsx-pretty'

  call plug#end()

" }}}

" commands {{{

  command! -bang -nargs=? -complete=dir FilesWithPreview
        \ call fzf#vim#files(
        \   <q-args>,
        \   fzf#vim#with_preview({'source': 'fd --type file'}),
        \   <bang>0,
        \ )

  command! -bang -nargs=? -complete=dir FilesWithPreviewAndHiddenFiles
        \ call fzf#vim#files(
        \   <q-args>,
        \   fzf#vim#with_preview({'source': 'fd --type file --hidden --exclude .git'}),
        \   <bang>0,
        \ )

  command! -bang -nargs=? -complete=dir GitFilesWithPreview
        \ call fzf#vim#files(
        \   <q-args>,
        \   fzf#vim#with_preview({'source': 'git ls-files'}),
        \   <bang>0,
        \ )

  command! -bang -nargs=* RgWithPreview
        \ call fzf#vim#grep(
        \   'rg          --column --line-number --no-heading '.shellescape(<q-args>),
        \   1,
        \   fzf#vim#with_preview(),
        \   <bang>0,
        \ )

  command! -bang -nargs=* RgWithPreviewAndHiddenFiles
        \ call fzf#vim#grep(
        \   'rg --hidden --column --line-number --no-heading '.shellescape(<q-args>),
        \   1,
        \   fzf#vim#with_preview(),
        \   <bang>0,
        \ )

  command! -bang -nargs=* GitGrepWithPreview
        \ call fzf#vim#grep(
        \   'git grep '.shellescape(<q-args>),
        \   1,
        \   fzf#vim#with_preview(),
        \   <bang>0,
        \ )

  " https://vi.stackexchange.com/a/8535/1956
  command! Cnext try | cnext | catch | cfirst | catch | endtry
  command! Cprev try | cprev | catch | clast  | catch | endtry
  command! Lnext try | lnext | catch | lfirst | catch | endtry
  command! Lprev try | lprev | catch | llast  | catch | endtry

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
  nnoremap <silent> <Leader>D :Bwipeout!<CR>
  nnoremap <silent> <Leader>e :Explore<CR>
  nnoremap <silent> <Leader>f :FilesWithPreview<CR>
  nnoremap <silent> <Leader>F :FilesWithPreviewAndHiddenFiles<CR>
  " <Leader>g git commands leader (see below)
  " <Leader>l LToggle
  " <Leader>q QToggle
  nnoremap <silent> <Leader>r :RgWithPreview<CR>
  nnoremap <silent> <Leader>R :RgWithPreviewAndHiddenFiles<CR>
  " <Leader>v vimrc commands leader (see below)

  nnoremap <silent> <Leader>gd       :Gvdiffsplit<CR>
  nnoremap <silent> <Leader>gf       :GitFilesWithPreview<CR>
  nnoremap <silent> <Leader>gg       :GitGrepWithPreview<CR>
  nnoremap <silent> <Leader>gl       :Commits<CR>
  nnoremap <silent> <Leader>gm       :Git mergetool<CR>
  nnoremap <silent> <Leader>gw       :Gwrite<CR>
  nnoremap <silent> <Leader>g<Space> :G<Space>

  nnoremap <silent> <Leader>ve :edit ~/.vimrc<CR>
  nnoremap <silent> <Leader>vs :source ~/.vimrc<CR>
  nnoremap <silent> <Leader>vu :PlugUpdate<CR>
  nnoremap <silent> <Leader>vU :PlugUpdate!<CR>

  " allow <C-W> mappings without releasing the prefix key
  nnoremap <C-W><C-Q> <C-W>q

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
