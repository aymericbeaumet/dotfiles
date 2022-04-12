-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

require('packer').startup(function(use)
	use {
		'shaunsingh/nord.nvim',
		config = function() vim.cmd([[
      set termguicolors
      colorscheme nord
    ]]) end
	}

	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'kyazdani42/nvim-web-devicons'},
		config = function() require('lualine').setup { options = { theme = 'nord' } } end
	}

	use {
		'kyazdani42/nvim-tree.lua',
		requires = { 'kyazdani42/nvim-web-devicons' },
		config = function() require('nvim-tree').setup() end
	}

	use {
		'git@github.com:aymericbeaumet/vim-symlink.git',
		requires = { 'moll/vim-bbye' }
	}

	use {
		'nvim-telescope/telescope.nvim',
		requires = { 'nvim-lua/plenary.nvim' },
		config = function()
			vim.cmd([[
			nnoremap <leader>b <cmd>Telescope buffers<cr>
			nnoremap <leader>f <cmd>Telescope find_files<cr>
			nnoremap <leader>r <cmd>Telescope live_grep<cr>
			]])
		end
	}

	use {
		'numToStr/Comment.nvim',
		config = function() require('Comment').setup() end
	}

	use 'tpope/vim-abolish'
	use 'tpope/vim-repeat'
	use 'tpope/vim-surround'
	use 'tpope/vim-unimpaired'

  use {
    'tpope/vim-eunuch',
    config = function()
	    vim.cmd('cnoreabbrev Remove Delete')
    end
  }

	use {
		'airblade/vim-rooter',
		config = function()
			vim.cmd([[
			let g:rooter_patterns = ['.git']
			let g:rooter_cd_cmd = 'lcd'
			let g:rooter_silent_chdir = 1
			let g:rooter_resolve_links = 1
			]])
		end
	}

	use {
		'phaazon/hop.nvim',
		branch = 'v1',
		config = function()
			require('hop').setup {
				keys = 'Z/X.C,VMQ;WYFUPLAORISETN',
				uppercase_labels = true,
			}
		end
	}

	use {
		'neoclide/coc.nvim',
		branch = 'release',
		config = function()
			vim.cmd([[
			let g:coc_global_extensions = [
			\   'coc-eslint8',
			\   'coc-go',
			\   'coc-rust-analyzer',
			\   'coc-svelte',
			\   'coc-tsserver',
			\ ]
			]])
		end
	}

	use {
		'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup({
        disable_filetype = { "TelescopePrompt" , "vim" },
      })
    end
	}

	use 'hashivim/vim-terraform'
	use 'evanleck/vim-svelte'
end)

-- legacy
vim.cmd([[
" init {{{

  filetype plugin indent on
  syntax on
  " set encoding=UTF-8
  " set fileencodings=utf-8
  " scriptencoding utf-8
  let mapleader = ' '
  let maplocalleader = ' '

" }}}

" autocmd {{{

augroup initvim

  autocmd!

  " custom mappings for some filetypes
  autocmd FileType rust,go nnoremap <silent> <buffer> <C-]> :call CocAction('jumpDefinition')<CR>zz

  " auto-import for go on save
  autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')

  " wrap at 80 characters for markdown
  autocmd BufRead,BufNewFile *.md setlocal textwidth=80

  " delete whitespaces
  autocmd BufWritePre * :%s/\s\+$//e

augroup END

" }}}

" commands {{{

  " https://vi.stackexchange.com/a/8535/1956
  command! Cnext try | cnext | catch | silent! cfirst | endtry
  command! Cprev try | cprev | catch | silent! clast  | endtry
  command! Lnext try | lnext | catch | silent! lfirst | endtry
  command! Lprev try | lprev | catch | silent! llast  | endtry

" }}}

" mappings {{{

  set timeoutlen=500 " time to wait when a part of a mapped sequence is typed
  set ttimeoutlen=0  " instant insert mode exit using escape

  vnoremap <silent> <CR> :<C-U>'<,'>w !squeeze -1 --url --open<CR><CR>

  vnoremap <silent> <Leader>s :sort<CR>

  nmap <Leader><Leader>s <Plug>(easymotion-overwin-f)

  nnoremap <silent> <Leader>/ :BLines<CR>

  nnoremap <silent> <Leader>b :Buffers<CR>

  " <Leader>c<Space> nerdcommenter
  nnoremap <silent> <Leader>ce :e ~/.config/nvim/coc-settings.json<CR>
  nnoremap <silent> <Leader>cu :CocUpdate<CR>

  nnoremap <silent> <Leader>d :Bwipeout!<CR>

  nnoremap <silent> <Leader>e :NvimTreeToggle<CR>

  nnoremap <silent> <Leader>f :Files<CR>

  nnoremap <silent> <Leader>pc :PlugClean<CR>
  nnoremap <silent> <Leader>pu :PlugUpdate<CR>:CocUpdate<CR>:CocCommand go.install.tools<CR>

  nnoremap <silent> <Leader>r :Ripgrep<CR>

  nnoremap <silent> <Leader>ve :e ~/.config/nvim/init.vim<CR>
  nnoremap <silent> <Leader>vs :source ~/.config/nvim/init.vim<CR>

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
  nnoremap <silent> * *zz
  nnoremap <silent> # #zz
  nnoremap <silent> <C-I> <C-I>zz
  nnoremap <silent> <C-O> <C-O>zz

  " trigger completion
  "inoremap <silent><expr> <C-SPACE> coc#refresh()
  "inoremap <silent><expr> <TAB>
      "\ pumvisible() ? coc#_select_confirm() :
      "\ <SID>check_back_space() ? "\<TAB>" :
      "\ coc#refresh()
  "function! s:check_back_space() abort
    "let col = col('.') - 1
    "return !col || getline('.')[col - 1]  =~# '\s'
  "endfunction

  " navigate diagnostics
  "nmap <silent> [d <Plug>(coc-diagnostic-prev)
  "nmap <silent> ]d <Plug>(coc-diagnostic-next)

  " show documentation
  "nnoremap <silent> K :call <SID>show_documentation()<CR>
  "function! s:show_documentation()
    "if (index(['vim','help'], &filetype) >= 0)
      "execute 'h '.expand('<cword>')
    "elseif (coc#rpc#ready())
      "call CocActionAsync('doHover')
    "else
      "execute '!' . &keywordprg . " " . expand('<cword>')
    "endif
  "endfunction

  " convenient insert mode mappings
  inoremap <silent> <C-A> <Home>
  inoremap <silent> <C-B> <Left>
  inoremap <silent> <C-D> <Del>
  inoremap <silent> <C-E> <End>
  inoremap <silent> <C-F> <Right>
  inoremap <silent> <C-H> <Backspace>

  " disable some bindings
  nnoremap Q <Nop>
  nnoremap q: <Nop>

" }}}

" buffer
set autoread " watch for file changes by other programs
set hidden " when a tab is closed, do not delete the buffer

" cursor
set nostartofline " leave my cursor alone
set scrolloff=8 " keep at least 8 lines after the cursor when scrolling
set sidescrolloff=10 " (same as `scrolloff` about columns during side scrolling)
set virtualedit=block " allow the cursor to go in to virtual places
set cursorline " color the cursorline

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
set number " show line numbers

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
let &undodir = expand('~/.config/nvim/tmp/undo//')
]])
