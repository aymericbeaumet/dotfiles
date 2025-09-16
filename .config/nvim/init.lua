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
vim.o.autoindent = true -- auto-indent new lines

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
vim.o.laststatus = 2 -- always show statusline in the last window
vim.o.statusline = "%f%=%l:%c %p%%" -- statusline format

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
	{ "n", "'A", "<cmd>edit ~/.config/alacritty/alacritty.toml<cr>" },
	{ "n", "'B", "<cmd>edit ~/.dotfiles/Brewfile<cr>" },
	{ "n", "'G", "<cmd>edit ~/.gitconfig<cr>" },
	{ "n", "'K", "<cmd>edit ~/.config/karabiner/karabiner.json<cr>" },
	{ "n", "'R", "<cmd>edit ~/.aerospace.toml<cr>" },
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
	{ "v", "<cr>", ":<C-U>'<,'>w !squeeze -1 --url --open<cr><cr>" },
	-- lsp
	{ "n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>" },
	{ "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<cr>zz" },
	{ "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>zz" },
	{ "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>zz" },
	-- navigation
	{ "n", "<c-w><bs>", "<c-w>h" },
	{ "n", "<c-o>", "<c-o>zz" },
	{ "n", "n", "nzz" },
	{ "n", "N", "Nzz" },
	{ "n", "<c-]>", "<c-]>zz" },
}) do
	vim.keymap.set(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true })
end

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
	"hashivim/vim-terraform",
	"RRethy/vim-illuminate",
	"farmergreg/vim-lastplace",
	"lewis6991/gitsigns.nvim",
	"joerdav/templ.vim",
	"evanleck/vim-svelte",
	"pangloss/vim-javascript",
	"othree/html5.vim",

	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-lua/popup.nvim",
			"jvgrootveld/telescope-zoxide",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			local actions = require("telescope.actions")

			require("telescope.pickers.layout_strategies").horizontal_merged = function(
				picker,
				max_columns,
				max_lines,
				layout_config
			)
				local layout = require("telescope.pickers.layout_strategies").horizontal(
					picker,
					max_columns,
					max_lines,
					layout_config
				)

				layout.prompt.title = ""
				layout.prompt.borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }

				layout.results.title = ""
				layout.results.borderchars = { "─", "│", "─", "│", "├", "┤", "┘", "└" }
				layout.results.line = layout.results.line - 1
				layout.results.height = layout.results.height + 1

				if layout.preview then
					layout.preview.title = ""
					layout.preview.borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }
				end

				return layout
			end

			require("telescope").setup({
				defaults = {
					sorting_strategy = "ascending",
					layout_strategy = "horizontal_merged",
					layout_config = {
						prompt_position = "top",
						width = function(_, max_columns)
							return max_columns
						end,
						height = function(_, _, max_lines)
							return max_lines
						end,
					},
					mappings = {
						i = {
							["<esc>"] = actions.close,
						},
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
			vim.g.EasyMotion_keys = "TNSERIAOPLFUWYQ"
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

	-- completion
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
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			vim.o.pumheight = 15

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

	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		after = { "cmp-nvim-lsp" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({ automatic_installation = true })

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = false -- disable snippets

			local flags = { debounce_text_changes = 150 }

			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
			}

			local on_attach = function(client, bufnr)
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
			end

			for lsp, settings in pairs({
        gopls = {
          directoryFilters = { "-mocks" },
        },
				rust_analyzer = {
					["rust-analyzer"] = {
						cargo = { loadOutDirsFromCheck = true },
						procMacro = { enable = true },
						checkOnSave = { command = "clippy" },
					},
				},
				ts_ls = {},
				templ = {},
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

	-- linting
	{
		"mfussenegger/nvim-lint",
		config = function()
			require("lint").linters_by_ft = {
				dockerfile = { "hadolint" },
				go = { "golangcilint" },
				proto = { "buf_lint" },
				template = { "templ" },
			}

			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},

	-- formatting
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				format_after_save = {
					lsp_fallback = true,
				},
				formatters_by_ft = {
					go = { "goimports", "gofumpt" },
					html = { "prettier" },
					javascript = { "prettier" },
					lua = { "stylua" },
					proto = { "buf" },
					python = { "ruff" },
					rust = { "rustfmt" },
					shell = { "shellharden" },
					svelte = { "prettier" },
					template = { "templ" },
					terraform = { "terraform_fmt" },
					typescript = { "prettier" },
				},
			})

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					require("conform").format({
						async = true,
						bufnr = args.buf,
					})
				end,
			})
		end,
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- error reporting
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
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

  -- bindings
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 350,
    },
    keys = {
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search current buffer" },
      { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Search buffers" },
      { "<leader>d", "<cmd>bp | sp | bn | bd<cr>", desc = "Close the current buffer" },
      {
        "<leader>f",
        "<cmd>Telescope find_files find_command=fd,--type,file,--hidden,--follow,--strip-cwd-prefix<cr>",
        desc = "Search file names in current working directory",
      },
      { "<leader>l", group = "lsp" },
      { "<leader>lA", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code action" },
      { "<leader>lR", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename symbol" },
      { "<leader>ld", "<cmd>lua vim.lsp.buf.declaration()<cr>zz", desc = "Go to declaration" },
      { "<leader>li", "<cmd>lua vim.lsp.buf.implementation()<cr>zz", desc = "Go to implementation" },
      { "<leader>ll", "<cmd>lua vim.lsp.buf.document_symbol()<cr>", desc = "List symbols" },
      { "<leader>lr", "<cmd>lua vim.lsp.buf.references()<cr>", desc = "List references" },
      { "<leader>lt", "<cmd>lua vim.lsp.buf.type_definition()<cr>zz", desc = "Go to type definition" },
      { "<leader>p", "<cmd>Telescope commands<cr>", desc = "Search commands" },
      { "<leader>q", "<cmd>call ToggleQuickfixList()<cr>", desc = "Toggle quickfix list" },
      {
        "<leader>r",
        "<cmd>Telescope live_grep vimgrep_arguments=rg,--color=never,--no-heading,--with-filename,--line-number,--column,--smart-case,--hidden<cr>",
        desc = "Search file contents in current working directory",
      },
      { "<leader>s", "<Plug>(easymotion-overwin-f)", desc = "Easymotion search" },
      { "<leader>z", "<cmd>Telescope zoxide list<cr>", desc = "Search frequent directories" },
    },
  },

  -- avante
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
      provider = "claude",
      providers = {
        claude = {
          endpoint = "https://api.anthropic.com",
          model = "claude-sonnet-4-20250514",
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 4096,
          },
        },
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  }
})
