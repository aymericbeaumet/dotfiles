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
		event = "BufReadPost",
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
		cmd = "Oil",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent directory in Oil" } },
		config = function()
			require("oil").setup({
				view_options = {
					show_hidden = true,
				},
			})
		end,
	},

	-- File tree explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<leader>t", "<cmd>Neotree toggle<cr>", desc = "Toggle tree explorer" },
		},
		opts = {
			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function()
						vim.schedule(function()
							-- quit nvim if neo-tree is the last open window
							local wins = vim.api.nvim_list_wins()
							local non_floating = vim.tbl_filter(function(w)
								return vim.api.nvim_win_get_config(w).relative == ""
							end, wins)
							if #non_floating == 1 then
								vim.cmd("quit")
							end
						end)
					end,
				},
			},
			filesystem = {
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
			window = {
				width = 35,
				mappings = {
					["<space>"] = "none", -- don't conflict with leader
					["<LeftRelease>"] = "open", -- single click to toggle folder / open file
				},
			},
			default_component_configs = {
				indent = {
					with_expanders = true,
				},
				git_status = {
					symbols = {
						added = "+",
						modified = "~",
						deleted = "-",
						renamed = "→",
						untracked = "?",
						ignored = "◌",
						unstaged = "○",
						staged = "●",
						conflict = "",
					},
				},
			},
		},
	},

	{
		"numToStr/Comment.nvim",
		keys = {
			{ "<leader>c<space>", mode = "n", desc = "Toggle comment (line)" },
			{ "<leader>c<space>", mode = "x", desc = "Toggle comment (visual selection)" },
		},
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
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"jvgrootveld/telescope-zoxide",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
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
			{ "<leader>p", "<cmd>Telescope commands<cr>", desc = "Search commands" },
			{ "<leader>z", "<cmd>Telescope zoxide list<cr>", desc = "Search frequent directories" },
			{ "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status" },
			{ "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
			{ "<leader>gC", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
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
					width = 0.8,
					height = 0.8,
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
		ft = { "sql", "pgsql" },
		config = function()
			vim.g.sql_type_default = "psql"
		end,
	},

	{
		"shaunsingh/nord.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			vim.g.nord_borders = true
			vim.g.nord_italic = true
			vim.g.nord_contrast = true

			require("nord").set()

			vim.diagnostic.config({
				virtual_text = {
					spacing = 4,
					prefix = "●",
				},
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = true,
					header = "",
					prefix = "",
				},
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
		event = "VeryLazy",
		config = function()
			vim.cmd("cnoreabbrev Delete  silent! Delete!")
			vim.cmd("cnoreabbrev Delete! silent! Delete!")
			vim.cmd("cnoreabbrev Remove  silent! Delete!")
			vim.cmd("cnoreabbrev Remove! silent! Delete!")
		end,
	},

	{
		"airblade/vim-rooter",
		event = "VeryLazy",
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
			labels = "tnseridhaoplfuwygjq",
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
			exclude = { filetypes = { "help", "lazy", "mason", "neo-tree", "oil" } },
		},
		config = function(_, opts)
			require("ibl").setup(opts)
			local hooks = require("ibl.hooks")
			hooks.register(hooks.type.ACTIVE, function(bufnr)
				return not vim.b[bufnr].large_file
			end)
		end,
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
			{ "<leader>x", group = "diagnostics" },
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
					ensure_installed = require("config.languages").lsp_servers(),
					automatic_enable = true,
				},
			},
			-- Auto-install linters and formatters (LSP servers are managed by mason-lspconfig)
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = require("config.languages").mason_tools(),
					auto_update = false,
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
			handlers = {},
			})

			-- Per-server settings from config/languages.lua
			for server, cfg in pairs(require("config.languages").lsp_configs()) do
				lsp.config(server, cfg)
			end

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

					-- reference highlights when supported (skip on large files)
					if client:supports_method("textDocument/documentHighlight") and not vim.b[buf].large_file then
						local hl_group = vim.api.nvim_create_augroup("aym.lsp_hl_" .. buf, {})
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							group = hl_group,
							buffer = buf,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							group = hl_group,
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
			lint.linters_by_ft = require("config.languages").linters_by_ft()
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
		event = "BufWritePre",
		opts = {
			format_on_save = {
				timeout_ms = 2000,
				lsp_format = "fallback",
			},
			formatters_by_ft = require("config.languages").formatters_by_ft(),
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- debugging
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<leader>dc", desc = "Continue" },
			{ "<leader>ds", desc = "Step over" },
			{ "<leader>di", desc = "Step into" },
			{ "<leader>do", desc = "Step out" },
			{ "<leader>db", desc = "Toggle breakpoint" },
			{ "<leader>dB", desc = "Conditional breakpoint" },
			{ "<leader>du", desc = "Toggle DAP UI" },
			{ "<leader>dr", desc = "Open REPL" },
			{ "<leader>dl", desc = "Run last" },
			{ "<leader>dt", desc = "Terminate" },
		},
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			{ "mason-org/mason.nvim", config = true },
			{
				"jay-babu/mason-nvim-dap.nvim",
				opts = {
					ensure_installed = require("config.languages").dap_adapters(),
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

			-- Language-specific DAP adapters/configurations from config/languages.lua
			require("config.languages").setup_dap(dap)
		end,
	},

	-- error reporting
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			win = { position = "top" },
		},
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
			{ "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
		},
	},

	-- bindings
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 350,
		},
		keys = {
			-- Debug group (keymaps on nvim-dap)
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
			-- Git group (telescope/git-worktree keymaps on their plugins)
			{ "<leader>g", group = "git" },
		},
	},

	-- git worktree integration
	{
		"polarmutex/git-worktree.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		keys = {
			{ "<leader>gw", "<cmd>Telescope git_worktree<cr>", desc = "Git worktrees" },
			{ "<leader>gW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create worktree" },
		},
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
			return {
				ensure_installed = require("config.languages").treesitter_parsers(),
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
