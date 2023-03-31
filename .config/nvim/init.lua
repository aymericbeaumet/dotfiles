-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

-- cursor
vim.o.scroll = 5 -- number of lines to scroll with ^U and ^D
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

-- interface
vim.o.mouse = "a" -- enable mouse support
vim.o.number = true -- show line numbers
vim.o.signcolumn = "number" -- display warnings/errors in the number column
vim.o.shortmess = "AaoOsIctF" -- disable vim welcome message / enable shorter messages
vim.o.showtabline = 0 -- never show tabline
vim.o.splitbelow = true -- slit below
vim.o.splitright = true -- split right
vim.o.cursorline = false -- do not highlight cursorline
vim.o.showmode = false -- do not show mode
vim.cmd([[
set statusline=
set statusline+=%f
set statusline+=%=
set statusline+=%l:%c\ %p%%
]])

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

-- plugins
require("packer").startup(function(use)
	use({
		"shaunsingh/nord.nvim",
		config = function()
			vim.o.termguicolors = true
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
	})

	use("preservim/nerdcommenter")
	use("tpope/vim-abolish")
	use("tpope/vim-repeat")
	use("tpope/vim-surround")
	use("tpope/vim-unimpaired")
	use("vitalk/vim-shebang")
	use("tpope/vim-fugitive")

	use("famiu/bufdelete.nvim")

	use({
		"junegunn/fzf.vim",
		requires = { "/opt/homebrew/opt/fzf" },
		config = function()
			vim.cmd([[
        command! -bang -nargs=? -complete=dir Files
            \ call fzf#vim#files(
            \   <q-args>,
            \   fzf#vim#with_preview({
            \     'source': 'fd --type file --hidden --follow --exclude .git --strip-cwd-prefix',
            \   }),
            \   <bang>0,
            \ )

        function! Ripgrep(query, fullscreen)
          let command_fmt = 'rg --hidden --glob "!.git" --column --line-number --no-heading --color=always --smart-case -- %s || true'
          let initial_command = printf(command_fmt, shellescape(a:query))
          let reload_command = printf(command_fmt, '{q}')
          let spec = {
          \   'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command, '--delimiter=:', '--nth=4..'],
          \ }
          call fzf#vim#grep(initial_command, 1, spec, a:fullscreen)
        endfunction
        command! -nargs=* -bang Ripgrep call Ripgrep(<q-args>, <bang>0)
      ]])
		end,
	})

	use({
		"tpope/vim-eunuch",
		config = function()
			vim.cmd("cnoreabbrev Delete Delete!")
			vim.cmd("cnoreabbrev Remove Delete!")
			vim.cmd("cnoreabbrev Remove! Delete!")
		end,
	})

	use({
		"airblade/vim-rooter",
		setup = function()
			vim.g.rooter_cd_cmd = "lcd"
			vim.g.rooter_patterns = { ".git" }
			vim.g.rooter_resolve_links = 1
			vim.g.rooter_silent_chdir = 1
		end,
	})

	use({
		"easymotion/vim-easymotion",
		setup = function()
			vim.g.EasyMotion_do_mapping = 0
			vim.g.EasyMotion_keys = "Z/X.C,VMQ;WYFUPLAORISETN"
			vim.g.EasyMotion_smartcase = 1
			vim.g.EasyMotion_use_smartsign_us = 1
			vim.g.EasyMotion_use_upper = 1
		end,
	})

	--
	-- Completion, autopairs, snippets
	--

	use({
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	})

	use({
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup({
				formatters = {
					insert_text = require("copilot_cmp.format").remove_existing,
				},
			})
		end,
	})

	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({
				map_c_h = true,
				map_c_w = true,
			})
		end,
	})

	use({
		"L3MON4D3/LuaSnip",
		requires = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	})

	use({
		"hrsh7th/nvim-cmp",
		requires = {
			-- sources
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			-- format
			"onsails/lspkind.nvim",
		},
		config = function()
			local cmp = require("cmp")
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local luasnip = require("luasnip")
			local handlers = require("nvim-autopairs.completion.handlers")
			local lspkind = require("lspkind")

			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,noinsert",
				},

				experimental = {
					ghost_text = true,
				},

				preselect = cmp.PreselectMode.None,

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
						mode = "symbol_text",
						max_width = 50,
						symbol_map = {
							Copilot = "",
						},
					}),
				},

				mapping = {
					["<Tab>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							cmp.confirm({
								behavior = cmp.ConfirmBehavior.Replace,
								select = false,
							})
						end
					end, { "i", "s" }),

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

				sources = cmp.config.sources({
					{ name = "luasnip" },
					{ name = "copilot" },
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	})

	--
	-- LSP, formatting, error reporting and languages support
	--

	use("jparise/vim-graphql")
	use("evanleck/vim-svelte")
	use("lifepillar/pgsql.vim")

	use({
		"neovim/nvim-lspconfig",
		after = {
			"cmp-nvim-lsp",
		},
		requires = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local flags = { debounce_text_changes = 150 }

			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
			}

			local on_attach = function(client, bufnr)
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

				-- we want to use null-ls for formatting
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
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

			require("mason").setup()
			require("mason-lspconfig").setup({ automatic_installation = true })
		end,
	})

	use({
		"jose-elias-alvarez/null-ls.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		run = [[
      brew install rust-analyzer;
      brew install golangci-lint; go install golang.org/x/tools/cmd/goimports@latest;
			npm install --global eslint prettier svelte-language-server tsserver;
      brew install shellharden shfmt shellcheck;
      brew install hadolint;
    ]],
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					-- golang
					null_ls.builtins.diagnostics.golangci_lint.with({
						prefer_local = ".bin",
					}),
					null_ls.builtins.formatting.goimports.with({
						prefer_local = ".bin",
					}),
					-- javascript, typescript, svelte, etc
					null_ls.builtins.diagnostics.eslint.with({
						prefer_local = "node_modules/.bin",
						extra_filetypes = { "svelte" },
					}),
					null_ls.builtins.formatting.prettier.with({
						prefer_local = "node_modules/.bin",
						extra_filetypes = { "svelte" },
					}),
					-- rust
					null_ls.builtins.formatting.rustfmt,
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

				on_attach = function(client)
					vim.cmd([[
              augroup LspFormatting
              autocmd! * <buffer>
              autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
              augroup END
            ]])
				end,
			})
		end,
	})

	use({
		"folke/trouble.nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
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
	})

	--
	-- Mappings
	--

	use({
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
				{ "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<cr>" },
				{ "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>" },
				{ "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>" },
			}) do
				vim.api.nvim_set_keymap(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true })
			end

			require("which-key").register({
				d = { "<cmd>Bwipeout!<cr>", "Close the current buffer" },
				s = { "<Plug>(easymotion-overwin-f)", "Easymotion search" },

				-- fzf
				["/"] = { "<cmd>BLines<cr>", "[FZF] Search current file" },
				b = { "<cmd>Buffers<cr>", "[FZF] Search buffers" },
				f = { "<cmd>Files<cr>", "[FZF] Search files" },
				p = { "<cmd>Commands<cr>", "[FZF] Search commands" },
				r = { "<cmd>Ripgrep<cr>", "[FZF] Search file contents" },

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

				-- vim
				v = {
					name = "vim",
					c = { "<cmd>PackerCompile<cr>", "Compile loader file" },
					s = { "<cmd>PackerSync<cr>", "Update plugins and compile loader file" },
					u = { "<cmd>PackerUpdate<cr>", "Update plugins" },
				},
			}, { prefix = "<leader>" })
		end,
	})
end)
