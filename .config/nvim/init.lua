-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

-- cursor
vim.o.scroll = 10 -- number of lines to scroll with ^U and ^D
vim.o.scrolloff = 10 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places

-- encoding
vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"

-- indentation
vim.o.expandtab = true -- replace tabs by spaces
vim.o.shiftwidth = 2 -- number of space to use for indent
vim.o.smarttab = true -- insert `shiftwidth` spaces instead of tabs
vim.o.softtabstop = 2 -- n spaces when using <Tab>
vim.o.tabstop = 2 -- n spaces when using <Tab>
vim.o.textwidth = 80 -- wrap lines at 80 characters

-- interface
vim.o.mouse = "a" -- enable mouse support
vim.o.mousemodel = extend -- right mouse extend selection
vim.o.number = true -- show line numbers
vim.o.relativenumber = false -- relative line numbers
vim.o.signcolumn = "number" -- display warnings/errors in the number column
vim.o.shortmess = "AaoOsIctF" -- disable vim welcome message / enable shorter messages
vim.o.showtabline = 0 -- never show tabline
vim.o.splitbelow = true -- slit below
vim.o.splitright = true -- split right
vim.o.cursorline = true -- highlight cursorline
vim.o.showmode = false -- do not show mode
vim.o.termguicolors = true -- enable true colors
vim.o.laststatus = 2 -- always show statusline
vim.o.statusline = "%f %{FugitiveStatusline()}%=%l:%c %p%%" -- statusline format

-- performance
vim.o.lazyredraw = true -- only redraw when needed
vim.o.ttyfast = true -- we have a fast terminal

-- safety net
vim.o.undofile = true -- store undos on disk
vim.o.updatetime = 300 -- flush swap files to disk on a regular basis

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
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- terminal
vim.api.nvim_create_augroup("TerminalGroup", { clear = true })
vim.api.nvim_create_autocmd("TermOpen", {
	command = "setlocal nonumber norelativenumber | startinsert",
	group = "TerminalGroup",
})
vim.api.nvim_create_autocmd("TermClose", {
	command = 'call feedkeys("q")',
	group = "TerminalGroup",
})

-- plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	"tpope/vim-abolish",
	"tpope/vim-repeat",
	"tpope/vim-surround",
	"tpope/vim-unimpaired",
	"vitalk/vim-shebang",
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"preservim/nerdcommenter",
	"evanleck/vim-svelte",
	"hashivim/vim-terraform",
	"RRethy/vim-illuminate",
	"farmergreg/vim-lastplace",
	"lewis6991/gitsigns.nvim",

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-lua/popup.nvim",
			"jvgrootveld/telescope-zoxide",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					sorting_strategy = "ascending",
					layout_config = {
						prompt_position = "top",
						width = 0.99999,
						height = 0.99999,
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})

			require("telescope").load_extension("fzf")
			require("telescope").load_extension("zoxide")
		end,
	},

	{
		"lifepillar/pgsql.vim",
		config = function()
			vim.g.sql_type_default = "psql"
		end,
	},

	{
		"shaunsingh/nord.nvim",
		config = function()
			vim.g.nord_borders = true
			vim.g.nord_italic = true
			vim.g.nord_contrast = true

			require("nord").set()

			vim.cmd([[
        sign define DiagnosticSignError text= texthl=LspDiagnosticsError linehl= numhl=
        sign define DiagnosticSignWarn  text= texthl=LspDiagnosticsWarn  linehl= numhl=
        sign define DiagnosticSignHint  text= texthl=LspDiagnosticsHint  linehl= numhl=
        sign define DiagnosticSignInfo  text= texthl=LspDiagnosticsInfo  linehl= numhl=
      ]])
		end,
	},

	{
		"milkypostman/vim-togglelist",
		config = function()
			vim.g.toggle_list_no_mappings = true
		end,
	},

	{
		"tpope/vim-eunuch",
		config = function()
			vim.cmd("cnoreabbrev Delete  silent! Delete!")
			vim.cmd("cnoreabbrev Delete! silent! Delete!")
			vim.cmd("cnoreabbrev Remove  silent! Delete!")
			vim.cmd("cnoreabbrev Remove! silent! Delete!")
		end,
	},

	{
		"airblade/vim-rooter",
		config = function()
			vim.g.rooter_cd_cmd = "lcd"
			vim.g.rooter_patterns = { ".git", "package-lock.json" }
			vim.g.rooter_resolve_links = 1
			vim.g.rooter_silent_chdir = 1
		end,
	},

	{
		"easymotion/vim-easymotion",
		config = function()
			vim.g.EasyMotion_do_mapping = 0
			vim.g.EasyMotion_keys = "AORISEDHTN"
			vim.g.EasyMotion_smartcase = 1
			vim.g.EasyMotion_use_smartsign_us = 1
			vim.g.EasyMotion_use_upper = 1
		end,
	},

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},

	{
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup({
				formatters = {
					insert_text = require("copilot_cmp.format").remove_existing,
				},
			})
		end,
	},

	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({
				map_c_h = true,
				map_c_w = true,
			})
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		version = false,
		event = "InsertEnter",
		dependencies = {
			-- sources
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			-- snippets engine
			"L3MON4D3/LuaSnip",
			-- style
			"onsails/lspkind.nvim",
		},
		config = function()
			local cmp = require("cmp")
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local luasnip = require("luasnip")
			local handlers = require("nvim-autopairs.completion.handlers")
			local lspkind = require("lspkind")

			vim.o.pumheight = 15

			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,noinsert",
				},

				sources = cmp.config.sources({
					{ name = "copilot" },
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),

				sorting = {
					priority_weight = 2,
					comparators = {
						-- https://github.com/zbirenbaum/copilot-cmp#comparators
						require("copilot_cmp.comparators").prioritize,
						-- Below is the default comparitor list and order for nvim-cmp
						cmp.config.compare.offset,
						-- cmp.config.compare.scopes, --this is commented in nvim-cmp too
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},

				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},

				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol",
						max_width = 50,
						symbol_map = { Copilot = "" },
					}),
				},

				mapping = {
					["<Tab>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = false,
					}, { "i", "s" }),

					["<C-space>"] = cmp.mapping(cmp.mapping.complete({ reason = cmp.ContextReason.Auto }), { "i" }),

					["<C-n>"] = cmp.mapping(
						cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
						{ "i" }
					),

					["<C-p>"] = cmp.mapping(
						cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
						{ "i" }
					),

					["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(vim.o.scroll), { "i" }),

					["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-vim.o.scroll), { "i" }),
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		after = { "cmp-nvim-lsp" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "gopls", "rust_analyzer" },
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- disable snippets
			capabilities.textDocument.completion.completionItem.snippetSupport = false

			local flags = { debounce_text_changes = 150 }

			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
			}

			local on_attach = function(client, bufnr)
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
			end

			for lsp, settings in pairs({
				gopls = {},
				svelte = {},
				tsserver = {},
				rust_analyzer = {
					["rust-analyzer"] = {
						cargo = {
							loadOutDirsFromCheck = true,
						},
						procMacro = {
							enable = true,
						},
						checkOnSave = {
							command = "clippy",
						},
					},
				},
			}) do
				require("lspconfig")[lsp].setup({
					capabilities = capabilities,
					flags = flags,
					handlers = handlers,
					on_attach = on_attach,
					settings = settings,
				})
			end
		end,
	},

	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

			null_ls.setup({
				sources = {
					-- rust
					null_ls.builtins.formatting.rustfmt,
					-- golang
					null_ls.builtins.diagnostics.golangci_lint.with({ prefer_local = ".bin" }),
					null_ls.builtins.formatting.goimports.with({ prefer_local = ".bin" }),
					null_ls.builtins.formatting.gofumpt.with({ prefer_local = ".bin" }),
					-- proto
					null_ls.builtins.diagnostics.buf.with({ prefer_local = ".bin" }),
					null_ls.builtins.formatting.buf.with({ prefer_local = ".bin" }),
					-- javascript, typescript, svelte
					null_ls.builtins.diagnostics.eslint.with({
						prefer_local = "node_modules/.bin",
						extra_filetypes = { "svelte" },
					}),
					null_ls.builtins.formatting.prettier.with({
						prefer_local = "node_modules/.bin",
						extra_filetypes = { "svelte" },
					}),
					-- lua
					null_ls.builtins.formatting.stylua,
					-- shell
					null_ls.builtins.diagnostics.shellcheck,
					null_ls.builtins.formatting.shellharden,
					null_ls.builtins.formatting.shfmt,
					-- dockerfile
					null_ls.builtins.diagnostics.hadolint,
					-- terraform
					null_ls.builtins.formatting.terraform_fmt,
				},
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
						vim.api.nvim_create_autocmd("BufWritePre", {
							group = augroup,
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format({
									bufnr = bufnr,
									filter = function(client)
										return client.name == "null-ls"
									end,
								})
							end,
						})
					end
				end,
			})
		end,
	},

	{
		"folke/trouble.nvim",
		dependencies = {
			"kyazdani42/nvim-web-devicons",
		},
		config = function()
			require("trouble").setup({
				position = "top",
				icons = true,
			})

			vim.diagnostic.config({
				float = { border = "rounded" },
				signs = true,
			})
		end,
	},

	{
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300 -- time to wait when a part of a mapped sequence is typed
			vim.o.ttimeoutlen = 0 -- instant insert mode exit using escape

			for _, mapping in ipairs({
				-- save current buffer
				{ "n", "<cr>", "<cmd>w<cr>" },
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
				{ "n", "<c-l>", "<cmd>nohl<cr>:redraw<cr>:checktime<cr><c-l>gjgk" },
				-- emulate permanent global marks
				{ "n", "'A", "<cmd>edit ~/.config/alacritty/alacritty.yml<cr>" },
				{ "n", "'B", "<cmd>edit ~/.dotfiles/Brewfile<cr>" },
				{ "n", "'K", "<cmd>edit ~/.config/karabiner/karabiner.json<cr>" },
				{ "n", "'T", "<cmd>edit ~/.tmux.conf<cr>" },
				{ "n", "'V", "<cmd>edit ~/.config/nvim/init.lua<cr>" },
				{ "n", "'Z", "<cmd>edit ~/.zshrc<cr>" },
				-- some zsh mappings in insert mode
				{ "i", "<c-a>", "<Home>" },
				{ "i", "<c-b>", "<Left>" },
				{ "i", "<c-d>", "<Del>" },
				{ "i", "<c-e>", "<End>" },
				{ "i", "<c-f>", "<Right>" },
				-- squeeze integration https://github.com/aymericbeaumet/squeeze
				{ "v", "<cr>", ":<C-U>'<,'>w !squeeze -1 --url --open<CR><CR>" },
				-- lsp
				{ "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>" },
				{ "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<cr>zz" },
				{ "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>zz" },
				{ "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>zz" },
				-- navigation
				{ "n", "<c-o>", "<c-o>zz" },
				{ "n", "n", "nzz" },
				{ "n", "N", "Nzz" },
			}) do
				vim.keymap.set(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true })
			end

			require("which-key").register({
				d = { "<cmd>bdelete!<cr>", "Close the current buffer" },
				D = { "<cmd>%bd|e#|bd#<cr>|'\"<cr>", "Close the current buffer" },
				q = { "<cmd>call ToggleQuickfixList()<cr>", "Toggle quickfix list" },
				s = { "<Plug>(easymotion-overwin-f)", "Easymotion search" },

				-- terminal
				e = { "<cmd>term yazi<cr>", "Start yazi" },
				g = { "<cmd>term lazygit<cr>", "Start Lazygit" },
				t = { "<cmd>term<cr>", "Start a terminal" },

				-- telescope
				b = { "<cmd>Telescope buffers<cr>", "Search buffers" },
				f = {
					"<cmd>Telescope find_files find_command=fd,--type,file,--hidden,--follow,--exclude,.git,--strip-cwd-prefix<cr>",
					"Search files",
				},
				p = { "<cmd>Telescope commands<cr>", "Search commands" },
				r = {
					"<cmd>Telescope live_grep prompt_title=Search\\ files vimgrep_arguments=rg,--color=never,--no-heading,--with-filename,--line-number,--column,--smart-case,--hidden,--glob,!git<cr>",
					"Search for a string",
				},
				z = {
					"<cmd>Telescope zoxide list prompt_title=Zoxide<cr>",
					"Search frequent directories",
				},

				-- lsp
				l = {
					name = "lsp",
					d = { "<cmd>lua vim.lsp.buf.declaration()<cr>", "Go to declaration" },
					i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Go to implementation" },
					l = { "<cmd>lua vim.lsp.buf.document_symbol()<cr>", "List symbols" },
					r = { "<cmd>lua vim.lsp.buf.references()<cr>", "List references" },
					t = { "<cmd>lua vim.lsp.buf.type_definition()<cr>", "Go to type definition" },
					A = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action" },
					R = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename symbol" },
				},
			}, { prefix = "<leader>", mode = "n" })
		end,
	},
})
