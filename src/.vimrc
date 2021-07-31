" Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
" Github: @aymericbeaumet/dotfiles

" init {{{

  filetype plugin indent on
  syntax on
  set encoding=UTF-8
  set fileencodings=utf-8
  scriptencoding utf-8
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" autocmd {{{

augroup vimrc

  autocmd!

  " custom mappings for some filetypes
  autocmd FileType rust,go,javascript,javascriptreact,typescript,typescriptreact,svelte nnoremap <silent> <buffer> <C-]> :call CocAction('jumpDefinition', 'drop')<CR>
  autocmd FileType rust,go,javascript,javascriptreact,typescript,typescriptreact,svelte nnoremap <silent> <buffer> K :call CocActionAsync('doHover')<CR>
  autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')

  " add support for .cjs
  autocmd BufNewFile,BufRead .*.cjs,*.cjs set ft=javascript

  " syntax highlighting for custom filetypes
  autocmd BufNewFile,BufRead *.tpl set ft=yaml

  " wrap at 80 characters for markdown
  autocmd BufRead,BufNewFile *.md setlocal textwidth=80

  " remember last position in file
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

  " delete whitespaces
  autocmd BufWritePre * :%s/\s\+$//e

augroup END

" }}}

" plugins {{{

  call plug#begin(expand('~/.vim/bundle'))

    Plug 'git@github.com:aymericbeaumet/vim-symlink.git' | Plug 'moll/vim-bbye'

    Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
    Plug 'Valloric/ListToggle'
    Plug 'arcticicestudio/nord-vim'
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

    Plug 'easymotion/vim-easymotion'
      let g:EasyMotion_keys = 'Z/X.C,VMQ;WYFUPLAORISETN'
      let g:EasyMotion_smartcase = 1
      let g:EasyMotion_use_smartsign_us = 1
      let g:EasyMotion_use_upper = 1
      let g:EasyMotion_do_mapping = 0

    Plug 'alvan/vim-closetag'
      let g:closetag_filetypes = 'html,xhtml,phtml,svelte,snippets'

    Plug 'neoclide/coc.nvim', { 'branch': 'release' }
      let g:coc_global_extensions = [
            \   'coc-go',
            \   'coc-html',
            \   'coc-json',
            \   'coc-prettier',
            \   'coc-rust-analyzer',
            \   'coc-snippets',
            \   'coc-svelte',
            \   'coc-tsserver',
            \ ]

    Plug 'jvirtanen/vim-hcl'
    Plug 'leafOfTree/vim-svelte-plugin'

  call plug#end()

" }}}

" commands {{{
  command! -bang -nargs=? -complete=dir Files
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

  vnoremap <silent> <CR> :<C-U>'<,'>w !squeeze -1 --url --open<CR><CR>

  vnoremap <silent> <Leader>s :sort<CR>

  nnoremap <silent> [l :Lprev<CR>
  nnoremap <silent> ]l :Lnext<CR>
  nnoremap <silent> [q :Cprev<CR>
  nnoremap <silent> ]q :Cnext<CR>

  nmap <Leader><Leader>s <Plug>(easymotion-overwin-f)

  nnoremap <silent> <Leader>/ :BLines<CR>

  nnoremap <silent> <Leader>b :Buffers<CR>

  " <Leader>c<Space> nerdcommenter
  nnoremap <silent> <Leader>ce :e ~/.vim/coc-settings.json<CR>
  nnoremap <silent> <Leader>cu :CocUpdate<CR>

  nnoremap <silent> <Leader>d :Bwipeout!<CR>

  nnoremap <silent> <Leader>f :Files<CR>

  nnoremap <silent> <Leader>gb :Git blame<CR>
  nnoremap <silent> <Leader>gd :Gvdiffsplit<CR>
  nnoremap <silent> <Leader>gl :Commits<CR>
  nnoremap <silent> <Leader>gm :Git mergetool<CR>
  nnoremap <silent> <Leader>gw :Gwrite<CR>

  " <Leader>l -> location list toggle

  nnoremap <silent> <Leader>pc :PlugClean<CR>
  nnoremap <silent> <Leader>pu :PlugUpdate<CR>:CocUpdate<CR>:CocCommand go.install.tools<CR>

  " <Leader>q -> quickfix list toggle

  nnoremap <silent> <Leader>r :Ripgrep<CR>

  nnoremap <silent> <Leader>ve :e ~/.vimrc<CR>
  nnoremap <silent> <Leader>vs :source ~/.vimrc<CR>

  nnoremap <silent> <Leader>ze :e ~/.zshrc<CR>

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
  nnoremap <silent> <C-L>      :<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-L>
  xnoremap <silent> <C-L> <C-C>:<C-u>nohl<CR>:redraw<CR>:checktime<CR><C-L>gv

  " keep the next/previous in the middle of the screen
  nnoremap <silent> n nzz
  nnoremap <silent> N Nzz

  " trigger completion
  inoremap <silent><expr> <c-space> coc#refresh()

  " }}}

" theme
set termguicolors     " enable true colors support
colorscheme nord

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
set fillchars="" " remove split separators
set laststatus=2 " always display status line
set nospell " disable spell checking
set shortmess=aoOsIctF " disable vim welcome message / enable shorter messages
set showcmd " show (partial) command in the last line of the screen
set splitbelow " slit below
set splitright " split right
set mouse=a " enable mouse support
set noinsertmode
set noshowmode " do not show the mode
set showtabline=0 " never show tabline
set nonumber

" performance
set lazyredraw " only redraw when needed
set ttyfast " we have a fast terminal

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
set undofile
set undolevels=1000
set undoreload=10000
let &undodir = expand('~/.vim/tmp/undo//')
