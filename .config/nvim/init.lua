-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

-- bindings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- cursor
vim.o.scrolloff = 10 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places

-- encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- indentation
vim.o.expandtab = true -- replace tabs by spaces
vim.o.shiftwidth = 2 -- number of space to use for indent
vim.o.smarttab = true -- insert `shiftwidth` spaces instead of tabs
vim.o.softtabstop = 2 -- n spaces when using <Tab>
vim.o.tabstop = 2 -- n spaces when using <Tab>

-- interface
vim.o.mouse = 'a' -- enable mouse support
vim.o.number = true -- show line numbers
vim.o.shortmess = 'aoOsIctF' -- disable vim welcome message / enable shorter messages
vim.o.showtabline = 0 -- never show tabline
vim.o.splitbelow = true -- slit below
vim.o.splitright = true -- split right

-- mappings
vim.o.timeoutlen = 500 -- time to wait when a part of a mapped sequence is typed
vim.o.ttimeoutlen = 0 -- instant insert mode exit using escape

-- performance
vim.o.lazyredraw = true -- only redraw when needed
vim.o.ttyfast = true -- we have a fast terminal
vim.o.updatetime = 1000 -- flush swap file to disk every second

-- search and replace
vim.o.ignorecase = true -- ignore case when searching
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

-- undo
vim.o.undofile = true

-- autocmds

vim.cmd([[
augroup initvim

autocmd!

" wrap at 80 characters for markdown
autocmd BufRead,BufNewFile *.md setlocal textwidth=80

" delete whitespaces
autocmd BufWritePre * :%s/\s\+$//e

augroup END
]])

-- mappings

-- mappings > leader
vim.api.nvim_set_keymap('v', '<cr>', '<cmd>w !squeeze -1 --url --open<cr><cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>d', '<cmd>Bwipeout!<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>vc', '<cmd>PackerClean<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ve', '<cmd>e ~/.config/nvim/init.lua<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>vs', '<cmd>PackerCompile<cr>:luafile ~/.config/nvim/init.lua<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>vu', '<cmd>PackerSync<cr>:CocUpdate<cr>:CocCommand go.install.tools<cr>', { noremap = true, silent = true })

-- mappings > save current buffer
vim.api.nvim_set_keymap('n', '<cr>', '<cmd>w<cr>', { noremap = true, silent = true })

-- mappings > better `j` and `k`
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'j', 'gj', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'k', 'gk', { noremap = true, silent = true })

-- mappings > copy from the cursor to the end of line using Y (matches D behavior)
vim.api.nvim_set_keymap('n', 'Y', 'y$', { noremap = true, silent = true })

-- mappings > keep the cursor in place while joining lines
vim.api.nvim_set_keymap('n', 'J', 'mZJ`Z', { noremap = true, silent = true })

-- mappings > reselect visual block after indent
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, silent = true })

-- mappings > clean screen and reload file
vim.api.nvim_set_keymap('n', '<c-l>', '<cmd>nohl<cr>:redraw<cr>:checktime<cr><C-L>', { noremap = true, silent = true })

-- mappings > keep "teleport" moves vertically centered
vim.api.nvim_set_keymap('n', 'n', 'nzz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'N', 'Nzz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '*', '*zz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '#', '#zz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<c-i>', '<c-i>zz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<c-o>', '<c-o>zz', { noremap = true, silent = true })

-- mappings > convenient insert mode mappings
vim.api.nvim_set_keymap('i', '<c-a>', '<home>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<c-b>', '<left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<c-d>', '<del>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<c-e>', '<end>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<c-f>', '<right>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<c-h>', '<backspace>', { noremap = true, silent = true })

-- mappings > disable some mappings
vim.api.nvim_set_keymap('n', '<up>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<down>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<left>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<right>', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'Q', '<nop>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'q:', '<nop>', { noremap = true, silent = true })

-- plugins
require('packer').startup(function(use)
  use 'tpope/vim-abolish'
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'
  use 'tpope/vim-unimpaired'

  use 'hashivim/vim-terraform'
  use 'evanleck/vim-svelte'

  use {
    'shaunsingh/nord.nvim',
    config = function()
      vim.o.termguicolors = true
      vim.cmd('colorscheme nord')
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
    config = function()
      require('nvim-tree').setup()
      vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { noremap = true, silent = true })
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup {
        defaults = { file_ignore_patterns = { ".git" } }
      }
      vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Telescope buffers<cr>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>Telescope find_files hidden=true<cr>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>r', '<cmd>Telescope live_grep hidden=true<cr>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>/', '<cmd>Telescope current_buffer_fuzzy_find case_mode=ignore_case<cr>', { noremap = true, silent = true })
    end,
  }

  use {
    'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end
  }

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
      vim.api.nvim_set_keymap('n', '<leader><leader>s', '<cmd>HopChar1<cr>', { noremap = true, silent = true })
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

      vim.cmd([[
      augroup nvim_coc

      autocmd!

      " jump to definition
      autocmd FileType rust,go nnoremap <silent> <buffer> <C-]> :call CocAction('jumpDefinition')<cr>zz

      " auto-import for go on save
      autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')

      augroup END

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
      "nnoremap <silent> K :call <SID>show_documentation()<cr>
      "function! s:show_documentation()
      "if (index(['vim','help'], &filetype) >= 0)
      "execute 'h '.expand('<cword>')
      "elseif (coc#rpc#ready())
      "call CocActionAsync('doHover')
      "else
      "execute '!' . &keywordprg . " " . expand('<cword>')
      "endif
      "endfunction
      ]])
    end
  }
end)
