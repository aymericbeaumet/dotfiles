-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

-- buffer
vim.o.autoread = true -- watch for file changes by other programs
vim.o.hidden = true -- when a tab is closed, do not delete the buffer

-- bindings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- command
vim.o.history = 10000 -- increase history size

-- cursor
vim.o.cursorline = true -- color the cursorline
vim.o.scrolloff = 8 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.startofline = false -- leave my cursor alone
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places

-- indentation
vim.o.autoindent = true -- auto-indentation
vim.o.expandtab = true -- replace tabs by spaces
vim.o.shiftwidth = 2 -- number of space to use for indent
vim.o.smarttab = true -- insert `shiftwidth` spaces instead of tabs
vim.o.softtabstop = 2 -- n spaces when using <Tab>
vim.o.tabstop = 2 -- n spaces when using <Tab>

-- interface
vim.o.fillchars = '' -- remove split separators
vim.o.laststatus = 2 -- always display status line
vim.o.mouse = 'a' -- enable mouse support
vim.o.number = true -- show line numbers
vim.o.shortmess = 'aoOsIctF' -- disable vim welcome message / enable shorter messages
vim.o.showcmd = true -- show (partial) command in the last line of the screen
vim.o.showtabline = 0 -- never show tabline
vim.o.spell = false -- disable spell checking
vim.o.splitbelow = true -- slit below
vim.o.splitright = true -- split right

-- performance
vim.o.lazyredraw = true -- only redraw when needed
vim.o.ttyfast = true -- we have a fast terminal

-- search and replace
vim.o.ignorecase = true -- ignore case when searching
vim.o.incsearch = true -- show matches as soon as possible
vim.o.smartcase = true -- smarter search case
vim.o.wildignorecase = true -- ignore case in file completion
vim.o.wildignore = '' -- remove default ignores
vim.o.wildignore = vim.o.wildignore .. '*.o,*.obj,*.so,*.a,*.dylib,*.pyc,*.hi' -- ignore compiled files
vim.o.wildignore = vim.o.wildignore .. '*.zip,*.gz,*.xz,*.tar,*.rar' -- ignore compressed files
vim.o.wildignore = vim.o.wildignore .. '*/.git/*,*/.hg/*,*/.svn/*' -- ignore SCM files
vim.o.wildignore = vim.o.wildignore .. '*.png,*.jpg,*.jpeg,*.gif' -- ignore image files
vim.o.wildignore = vim.o.wildignore .. '*.pdf,*.dmg' -- ignore binary files
vim.o.wildignore = vim.o.wildignore .. '.*.sw*,*~' -- ignore editor files
vim.o.wildignore = vim.o.wildignore .. '.DS_Store' -- ignore OS files
vim.o.wildmenu = true -- better command line completion menu
vim.o.wildmode = 'full' -- ensure better completion

-- undo
vim.o.undofile = true
vim.o.undolevels = 1000
vim.o.undoreload = 10000
-- let &undodir = expand('~/.config/nvim/tmp/undo//')

-- plugins
require('packer').startup(function(use)
	use {
		'shaunsingh/nord.nvim',
		config = function()
			vim.cmd([[
			set termguicolors
			colorscheme nord
			]])
		end
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
			nnoremap <silent> <leader>b <cmd>Telescope buffers<cr>
			nnoremap <silent> <leader>f <cmd>Telescope find_files<cr>
			nnoremap <silent> <leader>r <cmd>Telescope live_grep<cr>
      nnoremap <silent> <Leader>/ <cmd>Telescope current_buffer_fuzzy_find fuzzy=false case_mode=ignore_case<cr>
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
		setup = function()
			vim.g.rooter_patterns = { '.git' }
			vim.g.rooter_cd_cmd = 'lcd'
			vim.g.rooter_silent_chdir = 1
			vim.g.rooter_resolve_links = 1
		end
	}

	use {
		'phaazon/hop.nvim',
		branch = 'v1',
		config = function()
			require('hop').setup()
      vim.cmd("nnoremap <silent> <Leader><Leader>s :HopChar1<cr>")
		end
	}

	use {
		'neoclide/coc.nvim',
		branch = 'release',
		setup = function()
      vim.g.coc_global_extensions = {
        'coc-eslint8',
        'coc-go',
        'coc-rust-analyzer',
        'coc-svelte',
        'coc-tsserver',
      }
		end
	}

	use {
		'windwp/nvim-autopairs',
		config = function()
			require('nvim-autopairs').setup({
				disable_filetype = { 'TelescopePrompt' , 'vim' },
			})
		end
	}

	use 'hashivim/vim-terraform'
	use 'evanleck/vim-svelte'
end)

-- legacy
vim.cmd([[
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

  " <Leader>c<Space> nerdcommenter
  nnoremap <silent> <Leader>ce :e ~/.config/nvim/coc-settings.json<CR>
  nnoremap <silent> <Leader>cu :CocUpdate<CR>

  nnoremap <silent> <Leader>d :Bwipeout!<CR>

  nnoremap <silent> <Leader>e :NvimTreeToggle<CR>

  nnoremap <silent> <Leader>pc :PlugClean<CR>
  nnoremap <silent> <Leader>pu :PlugUpdate<CR>:CocUpdate<CR>:CocCommand go.install.tools<CR>

  nnoremap <silent> <Leader>ve :e ~/.config/nvim/init.lua<CR>
  nnoremap <silent> <Leader>vs :PackerCompile<CR>:source ~/.config/nvim/init.lua<CR>

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

]])
