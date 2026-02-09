return {
	{ "tpope/vim-abolish", event = "VeryLazy" },
	{ "tpope/vim-repeat", event = "VeryLazy" },
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},
	{ "tpope/vim-unimpaired", event = "VeryLazy" },
	{ "vitalk/vim-shebang", event = "VeryLazy" },
	{
		"ethanholz/nvim-lastplace",
		opts = {
			lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
			lastplace_ignore_filetype = { "gitcommit", "gitrebase" },
		},
	},

	-- Git signs in gutter with full functionality
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local map = function(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
				end
				-- Navigation
				map("n", "]h", function()
					gs.nav_hunk("next")
				end, "Next hunk")
				map("n", "[h", function()
					gs.nav_hunk("prev")
				end, "Previous hunk")
				-- Actions
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage hunk")
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Reset hunk")
				map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
				map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
				map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, "Blame line")
				map("n", "<leader>hd", gs.diffthis, "Diff this")
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, "Diff this ~")
				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
			end,
		},
	},

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
		"numToStr/Comment.nvim",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		config = function()
			local comment = require("Comment")

			comment.setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
				mappings = false, -- turn off default mappings
			})

			-- normal mode: comment current line
			vim.keymap.set("n", "<leader>c<space>", function()
				return require("Comment.api").toggle.linewise.current()
			end, { desc = "Toggle comment (line)", silent = true })

			-- visual mode: comment selection
			vim.keymap.set("x", "<leader>c<space>", function()
				return require("Comment.api").toggle.linewise(vim.fn.visualmode())
			end, { desc = "Toggle comment (visual selection)", silent = true })
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
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

			vim.diagnostic.config({
				float = { border = "rounded" },
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})
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
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				char = { enabled = false }, -- disable f/F/t/T enhancement
			},
		},
		keys = {
			{
				"<leader>s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
		},
	},

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		dependencies = {
			"copilotlsp-nvim/copilot-lsp",
		},
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},


	-- Claude Code integration
	{
		"greggh/claude-code.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
			{ "<leader>cC", "<cmd>ClaudeCodeContinue<cr>", desc = "Continue Claude conversation" },
			{ "<leader>cR", "<cmd>ClaudeCodeResume<cr>", desc = "Resume Claude conversation" },
		},
		opts = {
			window = {
				position = "float",
				float = {
					width = "90%",
					height = "90%",
					border = "rounded",
				},
			},
		},
	},

	-- Auto-pair brackets/quotes
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
			fast_wrap = { map = "<M-e>" },
		},
	},

	-- Indent guides
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPost", "BufNewFile" },
		main = "ibl",
		opts = {
			indent = { char = "│" },
			scope = { enabled = true, show_start = false, show_end = false },
			exclude = { filetypes = { "help", "lazy", "mason", "oil" } },
		},
	},

	-- TODO/FIXME highlighting
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next TODO",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous TODO",
			},
			{ "<leader>xt", "<cmd>TodoTelescope<cr>", desc = "Search TODOs" },
		},
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			-- Nerd Font powerline glyphs
			local separators = {
				round = { left = "\u{e0b4}", right = "\u{e0b6}" }, -- rounded
				arrow = { left = "\u{e0b0}", right = "\u{e0b2}" }, -- triangles
			}
			return {
				options = {
					theme = "nord",
					component_separators = "",
					section_separators = separators.round,
					globalstatus = true,
				},
				sections = {
					lualine_a = {
						{
							"mode",
							fmt = function(str)
								return str:sub(1, 1)
							end,
						},
					},
					lualine_b = {
						{ "branch", icon = "\u{e0a0}" },
						{
							"diff",
							symbols = { added = "+", modified = "~", removed = "-" },
						},
					},
					lualine_c = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = {
								error = "\u{f057} ",
								warn = "\u{f071} ",
								info = "\u{f05a} ",
								hint = "\u{f0eb} ",
							},
						},
						{
							"filename",
							path = 1,
							symbols = { modified = " \u{f111}", readonly = " \u{f023}", unnamed = "[No Name]" },
						},
					},
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
			}
		end,
	},

	-- completion (blink.cmp - faster than nvim-cmp)
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
			{
				"giuxtaposition/blink-cmp-copilot",
				dependencies = { "zbirenbaum/copilot.lua" },
			},
		},
		version = "*",
		event = "InsertEnter",
		opts = {
			keymap = {
				preset = "default",
				["<Tab>"] = { "select_and_accept", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-u>"] = { "scroll_documentation_up", "fallback" },
			},
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "copilot" },
				providers = {
					copilot = {
						name = "copilot",
						module = "blink-cmp-copilot",
						score_offset = 100,
						async = true,
					},
				},
			},
			completion = {
				accept = { auto_brackets = { enabled = true } },
				menu = { border = "rounded" },
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = { border = "rounded" },
				},
			},
			signature = { enabled = true, window = { border = "rounded" } },
		},
	},

	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			{ "mason-org/mason.nvim", config = true },
			{
				"mason-org/mason-lspconfig.nvim",
				opts = {
					ensure_installed = {
						"gopls",
						"rust_analyzer",
						"vtsls",
						"lua_ls",
						"bashls",
						"terraformls",
						"buf_ls",
						"dockerls",
						"html",
						"cssls",
						"tailwindcss",
						"svelte",
					},
					automatic_enable = true,
				},
			},
			-- Auto-install linters and formatters (LSP servers are managed by mason-lspconfig)
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = {
						-- Linters
						"eslint_d",
						"shellcheck",
						"hadolint",
						"golangci-lint",
						-- Formatters
						"stylua",
						"gofumpt",
						"goimports",
						"prettierd",
						"shfmt",
					},
					auto_update = true,
					run_on_start = true,
				},
			},
		},
		config = function()
			local lsp = vim.lsp
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local flags = { debounce_text_changes = 150 }

			-- Global defaults for all servers
			lsp.config("*", {
				capabilities = capabilities,
				flags = flags,
				handlers = {
					["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" }),
				},
			})

			-- Per-server tweaks
			lsp.config("gopls", {
				settings = { gopls = { directoryFilters = { "-mocks" } } },
			})
			lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						cargo = { loadOutDirsFromCheck = true },
						procMacro = { enable = true },
						check = { command = "clippy" },
					},
				},
			})
			lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})
			lsp.config("svelte", {
				settings = {
					svelte = {
						plugin = {
							svelte = { defaultScriptLanguage = "ts" },
						},
					},
				},
			})

			-- LSP UX niceties
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("aym.lsp", {}),
				callback = function(args)
					local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
					local buf = args.buf
					vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					-- Buffer-local LSP keymaps using callback form (idiomatic for Neovim 0.10+)
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
					end
					map("n", "K", vim.lsp.buf.hover, "LSP hover")
					map("n", "<c-]>", function()
						vim.lsp.buf.definition()
						vim.cmd("normal! zz")
					end, "LSP go to definition")
					map("n", "[d", function()
						vim.diagnostic.jump({ count = -1 })
						vim.cmd("normal! zz")
					end, "Previous diagnostic")
					map("n", "]d", function()
						vim.diagnostic.jump({ count = 1 })
						vim.cmd("normal! zz")
					end, "Next diagnostic")

					-- inlay hints & reference highlights when supported
					pcall(vim.lsp.inlay_hint.enable, true, { bufnr = buf })
					if client:supports_method("textDocument/documentHighlight") then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = buf,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd("CursorMoved", {
							buffer = buf,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})
		end,
	},

	-- linting
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				dockerfile = { "hadolint" },
				go = { "golangcilint" },
				proto = { "buf_lint" },
				sh = { "shellcheck" },
				-- web
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
			}
			local grp = vim.api.nvim_create_augroup("aym.lint", {})
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
				group = grp,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	-- formatting
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = {
				timeout_ms = 2000,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				-- Go
				go = { "gofumpt", "goimports" },
				-- Web
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				-- Rust / Lua / Shell / Proto
				rust = { "rustfmt" },
				lua = { "stylua" },
				sh = { "shfmt" },
				proto = { "buf" },
			},
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- debugging
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			{ "mason-org/mason.nvim", config = true },
			{
				"jay-babu/mason-nvim-dap.nvim",
				opts = {
					ensure_installed = { "delve", "codelldb", "js-debug-adapter" },
					automatic_installation = true,
					handlers = {}, -- use default mappings from the plugin
				},
			},
			{ "leoluz/nvim-dap-go", ft = "go" }, -- nice Go ergonomics
		},
		config = function()
			local dap, dapui = require("dap"), require("dapui")
			require("nvim-dap-virtual-text").setup()
			dapui.setup()

			-- Debugging keymaps under <leader>d
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
			vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step over" })
			vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
			vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Conditional breakpoint" })
			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
			vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
			vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run last" })
			vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })

			-- Go adapter helpers
			pcall(function()
				require("dap-go").setup()
			end)

			-- JS/TS with js-debug-adapter (pwa-node)
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "127.0.0.1",
				port = "${port}",
				executable = { command = "js-debug-adapter", args = { "${port}" } },
			}
			for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
				dap.configurations[ft] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
						runtimeExecutable = "node",
					},
				}
			end
		end,
	},

	-- error reporting
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("trouble").setup({
				win = { position = "top" },
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
			{ "<leader><leader>", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
			{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search current buffer" },
			{ "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Search buffers" },
			{
				"<leader>f",
				"<cmd>Telescope find_files find_command=fd,--type,file,--hidden,--follow,--strip-cwd-prefix<cr>",
				desc = "Search file names (cwd)",
			},
			{
				"<leader>F",
				function()
					require("telescope.builtin").find_files({
						find_command = { "fd", "--type", "file", "--hidden", "--follow" },
						cwd = vim.fn.expand("%:p:h"),
					})
				end,
				desc = "Search file names (file dir)",
			},
			{
				"<leader>r",
				"<cmd>Telescope live_grep vimgrep_arguments=rg,--color=never,--no-heading,--with-filename,--line-number,--column,--smart-case,--hidden<cr>",
				desc = "Search file contents (cwd)",
			},
			{
				"<leader>R",
				function()
					require("telescope.builtin").live_grep({
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
						cwd = vim.fn.expand("%:p:h"),
					})
				end,
				desc = "Search file contents (file dir)",
			},
			-- Debug group
			{ "<leader>d", group = "debug" },
			-- LSP group
			{ "<leader>l", group = "lsp" },
			{ "<leader>lA", vim.lsp.buf.code_action, desc = "Code action" },
			{ "<leader>lR", vim.lsp.buf.rename, desc = "Rename symbol" },
			{
				"<leader>ld",
				function()
					vim.lsp.buf.declaration()
					vim.cmd("normal! zz")
				end,
				desc = "Go to declaration",
			},
			{
				"<leader>li",
				function()
					vim.lsp.buf.implementation()
					vim.cmd("normal! zz")
				end,
				desc = "Go to implementation",
			},
			{ "<leader>ll", vim.lsp.buf.document_symbol, desc = "List symbols" },
			{ "<leader>lr", vim.lsp.buf.references, desc = "List references" },
			{
				"<leader>lt",
				function()
					vim.lsp.buf.type_definition()
					vim.cmd("normal! zz")
				end,
				desc = "Go to type definition",
			},
			{ "<leader>p", "<cmd>Telescope commands<cr>", desc = "Search commands" },
			{
				"<leader>q",
				function()
					local qf_exists = false
					for _, win in pairs(vim.fn.getwininfo()) do
						if win.quickfix == 1 then
							qf_exists = true
							break
						end
					end
					if qf_exists then
						vim.cmd("cclose")
					else
						vim.cmd("copen")
					end
				end,
				desc = "Toggle quickfix list",
			},
			{ "<leader>z", "<cmd>Telescope zoxide list<cr>", desc = "Search frequent directories" },
			-- Git group
			{ "<leader>g", group = "git" },
			{ "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
			{ "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
			{ "<leader>gC", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
			{ "<leader>gw", "<cmd>Telescope git_worktree<cr>", desc = "Git worktrees" },
			{ "<leader>gW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create worktree" },
		},
	},

	-- git worktree integration
	{
		"polarmutex/git-worktree.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telescope").load_extension("git_worktree")
		end,
	},

	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			-- Structural selections/motions
			"nvim-treesitter/nvim-treesitter-textobjects",
			-- Auto-close & rename tags (HTML/TSX/Svelte)
			"windwp/nvim-ts-autotag",
			-- Better comment contexts for JSX/Svelte/etc.
			{ "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
			-- Sticky context header (shows current function/class)
			{ "nvim-treesitter/nvim-treesitter-context", opts = { max_lines = 3, trim_scope = "outer" } },
		},
		opts = function()
			-- languages you use daily
			local ensure = {
				-- Core/editor
				"lua",
				"vim",
				"vimdoc",
				"query",
				"regex",
				"markdown",
				"markdown_inline",
				-- Go
				"go",
				"gomod",
				"gowork",
				"gosum",
				-- Rust
				"rust",
				-- Web
				"javascript",
				"typescript",
				"tsx",
				"json",
				"jsonc",
				"yaml",
				"toml",
				"html",
				"css",
				"scss",
				"svelte",
				-- Infra / data
				"proto",
				"terraform",
				"hcl",
				"sql",
				-- Shell & tooling
				"bash",
				"dockerfile",
			}

			return {
				ensure_installed = ensure,
				sync_install = false,

				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false, -- avoid double-highlighting
					-- disable Treesitter on very large files
					disable = function(_, buf)
						local max = 200 * 1024 -- 200 KB
						local ok2, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
						return ok2 and stats and stats.size > max
					end,
				},

				indent = { enable = true },

				incremental_selection = {
					enable = true,
					-- mnemonic: gnn (init), grn (grow), grm (shrink), grc (scope)
					keymaps = {
						init_selection = "gnn",
						node_incremental = "grn",
						node_decremental = "grm",
						scope_incremental = "grc",
					},
				},

				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["ap"] = "@parameter.outer",
							["ip"] = "@parameter.inner",
						},
						selection_modes = {
							["@function.outer"] = "V",
							["@class.outer"] = "V",
						},
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]f"] = "@function.outer",
							["]c"] = "@class.outer",
						},
						goto_previous_start = {
							["[f"] = "@function.outer",
							["[c"] = "@class.outer",
						},
					},
					swap = {
						enable = true,
						swap_next = { ["<leader>a"] = "@parameter.inner" },
						swap_previous = { ["<leader>A"] = "@parameter.inner" },
					},
				},
			}
		end,
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			-- Modern Treesitter-based folds (open by default)
			vim.o.foldmethod = "expr"
			vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.o.foldlevel = 99
		end,
	},
}
