" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)

" init {{{

  syntax enable
  filetype plugin indent on
  if has('vim_starting') | set encoding=UTF-8 | endif
  set fileencodings=utf-8
  scriptencoding utf-8
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" helpers {{{

function! s:is_following_space_character() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins'  } " pip3 install --upgrade neovim pynvim
      let g:deoplete#enable_at_startup = 1
      set completeopt=menuone,noinsert
      inoremap <silent><expr> <TAB>
            \ pumvisible() ? '<C-Y>' :
            \ <SID>is_following_space_character() ? "<TAB>" :
            \ deoplete#manual_complete()
    Plug 'fszymanski/deoplete-emoji'
    Plug 'Shougo/neco-vim'
    Plug 'w0rp/ale'
      nnoremap <silent> gd :ALEGoToDefinition<CR>
      nnoremap <silent> g<C-S> :ALEGoToDefinitionInSplit<CR>
      nnoremap <silent> g<C-V> :ALEGoToDefinitionInVSplit<CR>
      nnoremap <silent> [L :ALEFirst<CR>
      nnoremap <silent> [l :ALEPrevious<CR>
      nnoremap <silent> ]l :ALENext<CR>
      nnoremap <silent> ]L :ALELast<CR>
      let g:ale_sign_error = '⤫'
      let g:ale_sign_warning = '⚠'
      let g:ale_sign_info = 'ⓘ'
      let g:ale_sign_column_always = 1
      let g:ale_set_highlights = 1
      let g:ale_set_balloons = 1
      let g:ale_linters_explicit = 1
      let g:ale_lint_on_text_changed = 1
      let g:ale_lint_on_insert_leave = 1
      let g:ale_lint_on_enter = 1
      let g:ale_lint_on_save = 1
      let g:ale_lint_on_filetype_changed = 1
      let g:ale_fix_on_save = 1
      let g:ale_linters = {}
      let g:ale_fixers = {
            \   '*': ['remove_trailing_lines', 'trim_whitespace'],
            \ }
    Plug 'junegunn/vader.vim'

    " Dockerfile {{{
    Plug 'honza/dockerfile.vim', { 'do': 'brew install hadolint' }
    let g:ale_linters['dockerfile'] = ['hadolint']
    " }}}
    " Go {{{
    Plug 'fatih/vim-go', { 'do': 'go get -u github.com/golangci/golangci-lint/cmd/golangci-lint golang.org/x/tools/gopls golang.org/x/tools/cmd/goimports' }
    let g:ale_linters['go'] = ['golangci-lint', 'gopls']
    let g:ale_fixers['go'] = ['goimports']
    " }}}
    " GraphQL {{{
    Plug 'jparise/vim-graphql'
    let g:ale_fixers['graphql'] = ['prettier']
    " }}}
    " Git {{{
    Plug 'tpope/vim-git', { 'do': 'pip3 install --upgrade gitlint' }
    let g:ale_linters['gitcommit'] = 'gitlint'
    " }}}
    " HTML {{{
    let g:ale_fixers['html'] = ['prettier']
    " }}}
    " JavaScript (+ TypeScript + React + Node.js + JSX) {{{
    Plug 'pangloss/vim-javascript', { 'do': 'yarn global add eslint eslint-config-prettier eslint-plugin-import eslint-plugin-react jsonlint prettier typescript' }
      let g:javascript_plugin_jsdoc = 1
    Plug 'mxw/vim-jsx'
    Plug 'peitalin/vim-jsx-typescript'
    let g:ale_linters['javascript'] = ['eslint', 'tsserver']
    let g:ale_fixers['javascript'] = ['prettier']
    for language in ['javascript.jsx', 'typescript', 'typescript.tsx']
      let g:ale_linters[language] = g:ale_linters['javascript']
      let g:ale_fixers[language] = g:ale_fixers['javascript']
    endfor
    " }}}
    " JSON {{{
    Plug 'elzr/vim-json', { 'do': 'yarn global add jsonlint' }
    let g:ale_linters['json'] = ['jsonlint']
    let g:ale_fixers['json'] = ['prettier']
    " }}}
    " Markdown {{{
    Plug 'plasticboy/vim-markdown', { 'do': 'yarn global add markdownlint-cli' }
    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn'  }
      augroup vimrc_markdown_preview
        autocmd!
        autocmd FileType markdown nmap <silent><buffer> <leader>p <Plug>MarkdownPreview
      augroup END
    let g:ale_linters['markdown'] = ['markdownlint']
    let g:ale_fixers['markdown'] = ['prettier']
    " }}}
    " Python {{{
    Plug 'hdima/python-syntax', { 'do': 'pip3 install --upgrade pylint yapf futures' }
    let g:ale_linters['python'] = ['pylint']
    let g:ale_fixers['python'] = ['yapf']
    " }}}
    " Rust {{{
    Plug 'rust-lang/rust.vim', { 'do': 'rustup component add clippy rls rust-analysis rust-src rustfmt' }
    let g:ale_linters['rust'] = ['rls']
    let g:ale_fixers['rust'] = ['rustfmt']
    let g:ale_rust_rls_config = { 'rust': { 'clippy_preference': 'on' } }
    " }}}
    " Shell {{{
    Plug 'WolfgangMehner/vim-plugins', { 'rtp': 'bash-support', 'do': 'brew install shellcheck' }
    let g:ale_linters['sh'] = ['shellcheck']
    " }}}
    " Terraform {{{
    Plug 'hashivim/vim-terraform', { 'do': 'brew install tflint' }
    let g:ale_linters['terraform'] = ['tflint']
    " }}}
    " Vim {{{
    Plug 'vim-jp/syntax-vim-ex', { 'do': 'pip3 install --upgrade vim-vint' }
    let g:ale_linters['vim'] = ['vint']
    " }}}
    " YAML {{{
    Plug 'stephpy/vim-yaml', { 'do': 'pip3 install --upgrade yamllint' }
    let g:ale_linters['yaml'] = ['yamllint']
    let g:ale_fixers['yaml'] = ['prettier']
    " }}}
    " ZSH {{{
    Plug 'chrisbra/vim-zsh'
    " }}}

    Plug 'Asheq/close-buffers.vim'
      nnoremap <silent> <leader>D :CloseOtherBuffers<CR>
    Plug 'editorconfig/editorconfig-vim'
    Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb'
    Plug 'airblade/vim-gitgutter'
    Plug 'scrooloose/nerdtree' | Plug 'Xuyuanp/nerdtree-git-plugin' | Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
      nnoremap <silent> <leader>e :silent NERDTreeRefreshRoot<CR> \| :NERDTreeToggle<CR>
      nnoremap <silent> <leader>E :silent NERDTreeRefreshRoot<CR> \| :NERDTreeFind<CR>
      let g:NERDTreeMinimalUI = 1
      let g:NERDTreeMapOpenSplit = '<C-S>'
      let g:NERDTreeMapOpenVSplit = '<C-V>'
    Plug 'scrooloose/nerdcommenter'
      let g:NERDCommentWholeLinesInVMode = 1
      let g:NERDMenuMode = 0
      let g:NERDSpaceDelims = 1

    Plug 'alvan/vim-closetag'
      let g:closetag_filetypes = 'javascript,javascript.jsx,typescript,typescript.tsx'
      let g:closetag_xhtml_filetypes = g:closetag_filetypes
      let g:closetag_emptyTags_caseSensitive = 1
      let g:closetag_regions = {
            \ 'javascript': 'jsxRegion',
            \ 'javascript.jsx': 'jsxRegion',
            \ 'typescript': 'jsxRegion,tsxRegion',
            \ 'typescript.tsx': 'jsxRegion,tsxRegion',
            \ }
    Plug 'cohama/lexima.vim'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-eunuch'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-surround'
      let g:surround_indent = 1 " reindent with `=` after surrounding
    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_verbose = 0
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_keys = 'tnseriaodhplfuwyq;gjvmc,x.z/bk' " colemak
    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
      nnoremap <silent> <leader>/ :BLines<CR>
      nnoremap <silent> <leader>? BLines<CR>
      nnoremap <silent> <leader>b :Buffers<CR>
      nnoremap <silent> <leader>B :Lines<CR>
      nnoremap <silent> <leader>c :Commands<CR>
      nnoremap <silent> <leader>f :Files<CR>
      nnoremap <silent> <leader>F :Rg<CR>
      nnoremap <silent> <leader>gc :Commits<CR>
      nnoremap <silent> <leader>gf :GFiles<CR>
      nnoremap <silent> <leader>gs :GFiles?<CR>
      let g:fzf_action = {
            \   'ctrl-s': 'split',
            \   'ctrl-v': 'vsplit',
            \ }
      let g:fzf_buffers_jump = 1
    Plug 'farmergreg/vim-lastplace'
    " Plug 'aymericbeaumet/zshmappings.vim'
      let g:zshmappings_command_mode_search_history_tool = 'fzf.vim'
    Plug 'Valloric/ListToggle'

    Plug 'vim-airline/vim-airline'
      set noshowmode " hide the duplicate mode in bottom status bar
      let g:airline_theme = 'nord'
      let g:airline_powerline_fonts = 1
      let g:airline#extensions#ale#enabled = 1
      let g:airline_section_z = '%l:%c '
    Plug 'ryanoasis/vim-devicons'
    Plug 'arcticicestudio/nord-vim'
    Plug 'junegunn/goyo.vim'
      nnoremap <silent> <leader>z :Goyo<CR>

  call plug#end()

  call deoplete#custom#option({
        \   'sources': {
        \     '_': ['ale', 'buffer'],
        \     'gitcommit': ['emoji'],
        \     'markdown': ['emoji'],
        \     'vim': ['buffer', 'necovim'],
        \   },
        \   'min_pattern_length': 1,
        \ })
  call deoplete#custom#source('emoji', {
        \   'converters': ['converter_emoji'],
        \ })

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
set laststatus=2 " always display status line
set nospell " disable spell checking
set shortmess=at " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set textwidth=80 " 80 characters line
set number " display line numbers
set mouse=a " enable mouse support
augroup vimrc_format
  autocmd!
  autocmd FileType * setlocal formatoptions=crqn
augroup END

" Open the help pane vertically
augroup vimrc_help
  autocmd!
  autocmd BufEnter *.txt if &buftype == 'help' | wincmd L | endif
augroup END

" mappings {{{

  set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
  set ttimeoutlen=0 " instant insert mode exit using escape

  " save current buffer
  nnoremap <CR> :w<CR>

  " kill a buffer
  nnoremap <silent> <leader>d :bd<CR>

  " reload configuration
  nnoremap <leader>r :source $HOME/.vimrc<CR>

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

" }}}

" modeline
set modeline " enable modelines for per file configuration
set modelines=1 " consider the first/last lines

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
set t_Co=256
set t_ut=
set background=dark
colorscheme nord

" undo
if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir = expand('~/.vim/tmp/undo//')
endif
