-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

--# selene: allow(undefined_variable)
--# selene: allow(unscoped_variables)

-- bindings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- cursor
vim.o.scrolloff = 10 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places
vim.cmd([[
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END
]])

-- encoding
vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"

-- filetypes
vim.g.do_filetype_lua = 1
vim.g.did_load_filetypes = 0

-- indentation
vim.o.expandtab = true -- replace tabs by spaces
vim.o.shiftwidth = 2 -- number of space to use for indent
vim.o.smarttab = true -- insert `shiftwidth` spaces instead of tabs
vim.o.softtabstop = 2 -- n spaces when using <Tab>
vim.o.tabstop = 2 -- n spaces when using <Tab>

-- interface
vim.o.mouse = "a" -- enable mouse support
vim.o.number = false -- don't show line numbers
vim.o.shortmess = "aoOsIctF" -- disable vim welcome message / enable shorter messages
vim.o.showtabline = 0 -- never show tabline
vim.o.splitbelow = true -- slit below
vim.o.splitright = true -- split right

-- mappings
vim.o.timeoutlen = 500 -- time to wait when a part of a mapped sequence is typed
vim.o.ttimeoutlen = 0 -- instant insert mode exit using escape

-- performance
vim.o.lazyredraw = true -- only redraw when needed
vim.o.ttyfast = true -- we have a fast terminal

-- safety net
vim.o.undofile = true -- store undos on disk
vim.o.updatetime = 300 -- flush swap file to disk on a regular basis

-- search and replace
vim.o.ignorecase = true -- ignore case when searching
vim.o.smartcase = true -- smarter search case
vim.o.wildignorecase = true -- ignore case in file completion
vim.o.wildignore = "" -- remove default ignores
vim.o.wildignore = vim.o.wildignore .. "*.o,*.obj,*.so,*.a,*.dylib,*.pyc,*.hi" -- ignore compiled files
vim.o.wildignore = vim.o.wildignore .. "*.zip,*.gz,*.xz,*.tar,*.rar" -- ignore compressed files
vim.o.wildignore = vim.o.wildignore .. "*/.git/*,*/.hg/*,*/.svn/*" -- ignore SCM files
vim.o.wildignore = vim.o.wildignore .. "*.png,*.jpg,*.jpeg,*.gif" -- ignore image files
vim.o.wildignore = vim.o.wildignore .. "*.pdf,*.dmg" -- ignore binary files
vim.o.wildignore = vim.o.wildignore .. ".*.sw*,*~" -- ignore editor files
vim.o.wildignore = vim.o.wildignore .. ".DS_Store" -- ignore OS files

-- mappings
for _, mapping in ipairs({
	-- leader
	{ "n", "<leader>vc", "<cmd>PackerClean<cr>" },
	{ "n", "<leader>vs", "<cmd>luafile ~/.config/nvim/init.lua<cr>:PackerCompile<cr>" },
	{ "n", "<leader>vu", "<cmd>luafile ~/.config/nvim/init.lua<cr>:PackerSync<cr>" },
	-- save current buffer
	{ "n", "<cr>", "<cmd>w<cr>" },
	-- extract and open url from selection
	{ "v", "<cr>", "<cmd>'<,'>w !squeeze -1 --url --open<cr><cr>" },
	-- better `j` and `k`
	{ "n", "j", "gj" },
	{ "v", "j", "gj" },
	{ "n", "k", "gk" },
	{ "v", "k", "gk" },
	-- copy from the cursor to the end of line using Y (matches D behavior)
	{ "n", "Y", "y$" },
	-- keep the cursor in place while joining lines
	{ "n", "J", "mZJ`Z" },
	-- reselect visual block after indent
	{ "v", "<", "<gv" },
	{ "v", ">", ">gv" },
	-- clean screen and reload file
	{ "n", "<c-l>", "<cmd>nohl<cr>:redraw<cr>:checktime<cr><c-l>" },
	-- emulate permanent global marks
	{ "n", "'A", "<cmd>edit ~/.config/alacritty/alacritty.yml<cr>" },
	{ "n", "'B", "<cmd>edit ~/.dotfiles/Brewfile<cr>" },
	{ "n", "'D", "<cmd>edit ~/.dotfiles<cr>" },
	{ "n", "'V", "<cmd>edit ~/.config/nvim/init.lua<cr>" },
	{ "n", "'T", "<cmd>edit ~/.tmux.conf<cr>" },
	{ "n", "'Z", "<cmd>edit ~/.zshrc<cr>" },
	-- disable mappings (let's forget bad habits)
	{ "n", "<up>", "<nop>" },
	{ "n", "<down>", "<nop>" },
	{ "n", "<left>", "<nop>" },
	{ "n", "<right>", "<nop>" },
	{ "i", "<c-b>", "<nop>" },
	{ "i", "<c-f>", "<nop>" },
	{ "i", "<c-n>", "<nop>" },
	{ "i", "<c-p>", "<nop>" },
	{ "i", "<c-a>", "<nop>" },
	{ "i", "<c-e>", "<nop>" },
	{ "i", "<c-w>", "<nop>" },
	{ "i", "<m-d>", "<nop>" },
	{ "i", "<m-b>", "<nop>" },
	{ "i", "<m-f>", "<nop>" },
}) do
	vim.api.nvim_set_keymap(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true })
end

-- plugins
require("packer").startup(function(use)
	use("tpope/vim-abolish")
	use("tpope/vim-repeat")
	use("tpope/vim-surround")
	use("tpope/vim-unimpaired")

	use({
		"git@github.com:aymericbeaumet/vim-symlink.git",
		requires = { "moll/vim-bbye" },
	})

	use({
		"shaunsingh/nord.nvim",
		config = function()
			vim.o.termguicolors = true
			vim.g.nord_borders = true
			vim.g.nord_italic = true
			vim.cmd("colorscheme nord")
		end,
	})

	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = { theme = "nord" },
				sections = {
					lualine_c = {
						{ "filename", path = 1 },
					},
				},
				inactive_sections = {
					lualine_c = {
						{ "filename", path = 1 },
					},
				},
				extensions = { "nvim-tree", "symbols-outline" },
			})
		end,
	})

	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	use({
		"tpope/vim-eunuch",
		config = function()
			vim.cmd("cnoreabbrev Remove Delete")
		end,
	})

	use({
		"airblade/vim-rooter",
		setup = function()
			vim.g.rooter_patterns = { ".git" }
			vim.g.rooter_cd_cmd = "lcd"
			vim.g.rooter_silent_chdir = 1
			vim.g.rooter_resolve_links = 1
		end,
	})

	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({
				disable_filetype = { "TelescopePrompt", "vim" },
			})
		end,
	})

	use({
		"folke/trouble.nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("trouble").setup()
		end,
	})

	use({
		"lewis6991/gitsigns.nvim",
		config = function()
			local gitsigns = require("gitsigns")

			gitsigns.setup({
				current_line_blame = true,
			})

			-- previous git hunk
			vim.keymap.set("n", "]h", function()
				if vim.wo.diff then
					return "]h"
				end
				vim.schedule(function()
					gitsigns.next_hunk()
				end)
				return "<Ignore>"
			end, { expr = true })

			-- next git hunk
			vim.keymap.set("n", "[h", function()
				if vim.wo.diff then
					return "[h"
				end
				vim.schedule(function()
					gitsigns.prev_hunk()
				end)
				return "<Ignore>"
			end, { expr = true })
		end,
	})

	use({
		"tpope/vim-fugitive",
		requires = { "tpope/vim-rhubarb" },
		config = function()
			vim.cmd("cnoreabbrev GRemove GDelete")
			vim.api.nvim_set_keymap("n", "<leader>gb", "<cmd>GBrowse<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>Gvdiffsplit<cr>", { noremap = true, silent = true })
		end,
	})

	use({
		"neovim/nvim-lspconfig", -- neovim lsp plugin
		requires = {
			"hrsh7th/nvim-cmp", -- completion plugin
			"L3MON4D3/LuaSnip", -- snippet plugin
			"ray-x/lsp_signature.nvim", -- lsp signature plugin
			-- completion source plugins
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			vim.o.completeopt = "menu,menuone,noselect"

			local cmp = require("cmp")
			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<tab>"] = cmp.mapping.confirm({ select = true }),
					["<cr>"] = cmp.mapping.confirm({ select = true }),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
				}),
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
				}, {
					{ name = "luasnip" },
					{ name = "path", options = { trailing_slash = true } },
				}, {
					{ name = "buffer" },
				}),
				window = {
					documentation = cmp.config.window.bordered(),
				},
			})

			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			local capabilities = require("cmp_nvim_lsp").update_capabilities(
				vim.lsp.protocol.make_client_capabilities()
			)
			local flags = { debounce_text_changes = 150 }
			local on_attach = function(client, bufnr)
				local opts = { noremap = true, silent = true }
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

				vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ld", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>li", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
				vim.api.nvim_buf_set_keymap(
					bufnr,
					"n",
					"<leader>lt",
					"<cmd>lua vim.lsp.buf.type_definition()<CR>",
					opts
				)

				-- we want to use null-ls for formatting
				client.resolved_capabilities.document_formatting = false
				client.resolved_capabilities.document_range_formatting = false

				require("lsp_signature").on_attach({
					hi_parameter = "IncSearch",
					hint_enable = false,
					handler_opts = {
						border = "rounded",
					},
				}, bufnr)
			end
			for _, lsp in pairs({ "gopls", "rust_analyzer" }) do
				require("lspconfig")[lsp].setup({ capabilities = capabilities, flags = flags, on_attach = on_attach })
			end
		end,
	})

	use({
		"jose-elias-alvarez/null-ls.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					-- rust
					null_ls.builtins.formatting.rustfmt,
					-- golang
					null_ls.builtins.formatting.gofmt,
					null_ls.builtins.diagnostics.golangci_lint,
					-- dockerfile
					null_ls.builtins.diagnostics.hadolint,
					-- lua
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.diagnostics.selene,
					-- shell/zsh
					null_ls.builtins.formatting.shfmt,
					null_ls.builtins.formatting.shellharden,
					null_ls.builtins.diagnostics.shellcheck,
					null_ls.builtins.diagnostics.zsh,
					-- terraform
					null_ls.builtins.formatting.terraform_fmt,
				},

				on_attach = function(client)
					if client.resolved_capabilities.document_formatting then
						vim.cmd([[
              augroup LspFormatting
              autocmd! * <buffer>
              autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
              augroup END
              ]])
					end
				end,
			})
		end,
	})

	use({
		"phaazon/hop.nvim",
		branch = "v1",
		config = function()
			require("hop").setup()
			for _, mode in ipairs({ "n", "v", "o" }) do
				vim.api.nvim_set_keymap(mode, "<leader>s", "<cmd>HopChar1<cr>", { noremap = true, silent = true })
			end
		end,
	})

	use({
		"famiu/bufdelete.nvim",
		config = function()
			vim.api.nvim_set_keymap("n", "<leader>d", "<cmd>Bdelete!<cr>", { noremap = true, silent = true })
		end,
	})

	use({
		"kyazdani42/nvim-tree.lua",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup()
			vim.api.nvim_set_keymap("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>E", "<cmd>NvimTreeFocus<cr>", { noremap = true, silent = true })
		end,
	})

	use({
		"simrat39/symbols-outline.nvim",
		setup = function()
			vim.api.nvim_set_keymap("n", "<leader>o", "<cmd>SymbolsOutline<cr>", { noremap = true, silent = true })
		end,
	})

	use({
		"voldikss/vim-floaterm",
		setup = function()
			vim.g.floaterm_title = ""
			vim.g.floaterm_height = 0.80
			vim.g.floaterm_width = 0.80
			vim.g.floaterm_autoclose = 2
			vim.g.floaterm_autohide = 0
			vim.api.nvim_set_keymap(
				"n",
				"<leader>t",
				"<cmd>FloatermNew --cwd=<root><cr>",
				{ noremap = true, silent = true }
			)
		end,
	})

	use({
		"nvim-telescope/telescope.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			local actions = require("telescope.actions")
			require("telescope").setup({
				defaults = {
					file_ignore_patterns = { ".git" },
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden",
					},
					sorting_strategy = "ascending",
					layout_strategy = "horizontal",
					layout_config = {
						height = 0.80,
						width = 0.80,
						prompt_position = "top",
						preview_width = 0.55,
					},
					mappings = {
						i = {
							["<esc>"] = actions.close,
						},
					},
				},
				pickers = {
					find_files = {
						find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
					},
				},
			})
			for lhs, rhs in pairs({
				["<leader>/"] = "<cmd>Telescope current_buffer_fuzzy_find<cr>",
				["<leader>:"] = "<cmd>Telescope command_history<cr>",
				["<leader>b"] = "<cmd>Telescope buffers<cr>",
				["<leader>c"] = "<cmd>Telescope commands<cr>",
				["<leader>f"] = "<cmd>Telescope find_files<cr>",
				["<leader>r"] = "<cmd>Telescope live_grep<cr>",
			}) do
				vim.api.nvim_set_keymap("n", lhs, rhs, { noremap = true, silent = true })
			end
		end,
	})
end)
