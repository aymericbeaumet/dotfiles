-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles

--# selene: allow(undefined_variable)
--# selene: allow(unscoped_variables)

-- cursor
vim.o.scrolloff = 10 -- keep at least 8 lines after the cursor when scrolling
vim.o.sidescrolloff = 10 -- (same as `scrolloff` about columns during side scrolling)
vim.o.virtualedit = "block" -- allow the cursor to go in to virtual places
vim.o.cursorline = false

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
for _, mapping in ipairs({
	-- leader
	{ "n", "<leader>vc", "<cmd>PackerClean<cr>" },
	{ "n", "<leader>vs", "<cmd>luafile ~/.config/nvim/init.lua<cr>:PackerCompile<cr>" },
	{ "n", "<leader>vu", "<cmd>luafile ~/.config/nvim/init.lua<cr>:PackerSync<cr>" },
	{ "n", "<leader>q", "<cmd>q<cr>" },
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
	{ "n", "<c-l>", "<cmd>nohl<cr>:redraw<cr>:checktime<cr><c-l>" },
	-- emulate permanent global marks
	{ "n", "'A", "<cmd>edit ~/.config/alacritty/alacritty.yml<cr>" },
	{ "n", "'B", "<cmd>edit ~/.dotfiles/Brewfile<cr>" },
	{ "n", "'V", "<cmd>edit ~/.config/nvim/init.lua<cr>" },
	{ "n", "'T", "<cmd>edit ~/.tmux.conf<cr>" },
	{ "n", "'Z", "<cmd>edit ~/.zshrc<cr>" },
	-- some zsh mappings in insert mode
	{ "i", "<c-a>", "<Home>" },
	{ "i", "<c-b>", "<Left>" },
	{ "i", "<c-d>", "<Del>" },
	{ "i", "<c-e>", "<End>" },
	{ "i", "<c-f>", "<Right>" },
	{ "i", "<c-h>", "<Backspace>" },
	-- always center screen on jump commands
	{ "n", "<c-i>", "<c-i>zz" },
	{ "n", "<c-o>", "<c-o>zz" },
	{ "n", "N", "Nzz" },
	{ "n", "n", "nzz" },
	{ "n", "*", "*zz" },
	{ "n", "#", "#zz" },
}) do
	vim.api.nvim_set_keymap(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true })
end

-- extract and open url from selection
vim.cmd("vnoremap <silent> <CR> :<C-U>'<,'>w !squeeze -1 --url --open<CR><CR>")

-- plugins
require("packer").startup(function(use)
	use({
		"shaunsingh/nord.nvim",
		config = function()
			vim.o.termguicolors = true
			vim.g.nord_borders = true
			vim.g.nord_italic = true
			vim.cmd("colorscheme nord")
		end,
	})

	use({ "git@github.com:aymericbeaumet/vim-symlink.git", requires = { "moll/vim-bbye" } })
	use("tpope/vim-abolish")
	use("tpope/vim-repeat")
	use("tpope/vim-surround")
	use("tpope/vim-unimpaired")
	use("farmergreg/vim-lastplace")
	use("preservim/nerdcommenter")
	use("jiangmiao/auto-pairs")

	use("/opt/homebrew/opt/fzf")
	use({
		"junegunn/fzf.vim",
		config = function()
			vim.cmd([[
        command! -bang -nargs=? -complete=dir Files
            \ call fzf#vim#files(
            \   <q-args>,
            \   fzf#vim#with_preview({'source': 'fd --type file --hidden --exclude .git --strip-cwd-prefix'}),
            \   <bang>0,
            \ )

        function! Ripgrep(query, fullscreen)
          let command_fmt = 'rg --hidden --glob "!.git" --column --line-number --no-heading --color=always --smart-case -- %s || true'
          let initial_command = printf(command_fmt, shellescape(a:query))
          let reload_command = printf(command_fmt, '{q}')
          let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command, '--delimiter=:', '--nth=4..']}
          call fzf#vim#grep(initial_command, 1, spec, a:fullscreen)
        endfunction
        command! -nargs=* -bang Ripgrep call Ripgrep(<q-args>, <bang>0)
      ]])

			vim.api.nvim_set_keymap("n", "<leader>/", "<cmd>BLines<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>b", "<cmd>Buffers<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>f", "<cmd>Files<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>r", "<cmd>Ripgrep<cr>", { noremap = true, silent = true })
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
			vim.g.rooter_patterns = { ".git" }
			vim.g.rooter_cd_cmd = "lcd"
			vim.g.rooter_silent_chdir = 1
			vim.g.rooter_resolve_links = 1
		end,
	})

	use({
		"easymotion/vim-easymotion",
		setup = function()
			vim.g.EasyMotion_keys = "Z/X.C,VMQ;WYFUPLAORISETN"
			vim.g.EasyMotion_smartcase = 1
			vim.g.EasyMotion_use_smartsign_us = 1
			vim.g.EasyMotion_use_upper = 1
			vim.g.EasyMotion_do_mapping = 0
			vim.cmd("nmap <Leader>s <Plug>(easymotion-overwin-f)")
		end,
	})

	use("hashivim/vim-terraform")

	use({
		"folke/trouble.nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("trouble").setup()

			vim.diagnostic.config({
				signs = false, -- no sign in gutter
			})

			vim.api.nvim_set_keymap(
				"n",
				"<leader>d",
				"<cmd>TroubleToggle document_diagnostics<cr>",
				{ noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>t",
				"<cmd>TroubleToggle workspace_diagnostics<cr>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("n", "[t", "", {
				noremap = true,
				silent = true,
				callback = function()
					require("trouble").previous({ skip_groups = true, jump = true })
				end,
			})
			vim.api.nvim_set_keymap("n", "]t", "", {
				noremap = true,
				silent = true,
				callback = function()
					require("trouble").next({ skip_groups = true, jump = true })
				end,
			})
		end,
	})

	use({
		"neovim/nvim-lspconfig", -- neovim lsp config plugin
		run = "npm update -g npm typescript typescript-language-server vscode-langservers-extracted prettier svelte-language-server eslint",
		requires = {
			"hrsh7th/nvim-cmp", -- completion plugin
			"ray-x/lsp_signature.nvim", -- lsp signature plugin
			"SirVer/ultisnips", -- snippet plugin
			-- completion source plugins
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"quangnguyen30192/cmp-nvim-ultisnips",
		},
		config = function()
			local cmp = require("cmp")

			cmp.setup({
				completion = { completeopt = "menu,menuone,noinsert" },
				experimental = { ghost_text = true },
				preselect = cmp.PreselectMode.None,
				window = { documentation = cmp.config.window.bordered() },

				snippet = {
					expand = function(args)
						vim.fn["UltiSnips#Anon"](args.body)
					end,
				},

				mapping = {
					["<cr>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i" }),
					["<tab>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i", "c" }),
					["<C-e>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i", "c" }),
					["<C-n>"] = cmp.mapping(
						cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
						{ "i", "c" }
					),
					["<C-p>"] = cmp.mapping(
						cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
						{ "i", "c" }
					),
					["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i" }),
					["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i" }),
				},

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "ultisnips" },
				}, {
					{ name = "path" },
				}, {
					{ name = "buffer" },
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
				vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>", opts)
				vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>", opts)

				-- we want to use null-ls for formatting
				client.resolved_capabilities.document_formatting = false
				client.resolved_capabilities.document_range_formatting = false

				require("lsp_signature").on_attach({
					hi_parameter = "IncSearch",
					hint_enable = false,
					handler_opts = { border = "rounded" },
				}, bufnr)
			end

			local border = {
				{ "/", "FloatBorder" },
				{ "▔", "FloatBorder" },
				{ "\\", "FloatBorder" },
				{ "▕", "FloatBorder" },
				{ "/", "FloatBorder" },
				{ "▁", "FloatBorder" },
				{ "\\", "FloatBorder" },
				{ "▏", "FloatBorder" },
			}

			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
				["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
			}

			for _, lsp in pairs({ "gopls", "rust_analyzer", "html", "tsserver", "svelte" }) do
				require("lspconfig")[lsp].setup({
					capabilities = capabilities,
					flags = flags,
					on_attach = on_attach,
					handlers = handlers,
				})
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
					null_ls.builtins.formatting.gofmt.with({ extra_args = { "-s" } }),
					null_ls.builtins.formatting.goimports,
					null_ls.builtins.diagnostics.golangci_lint,
					-- javascript, typescript, svelte, etc
					null_ls.builtins.formatting.prettier.with({ extra_filetypes = { "svelte" } }),
					null_ls.builtins.diagnostics.eslint.with({ extra_filetypes = { "svelte" } }),
					-- lua
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.diagnostics.selene,
					-- shell
					null_ls.builtins.formatting.shfmt,
					null_ls.builtins.formatting.shellharden,
					null_ls.builtins.diagnostics.shellcheck,
					-- zsh
					null_ls.builtins.diagnostics.zsh,
					-- dockerfile
					null_ls.builtins.diagnostics.hadolint,
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
end)
