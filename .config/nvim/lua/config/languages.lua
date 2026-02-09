-- config/languages.lua
-- Single source of truth for all language tooling.
--
-- To add a new language, create a new entry with all of these keys:
--   treesitter  – parser names to install                         (list, or {})
--   lsp         – { server_name = { [settings = ...] } }         (table, or {})
--   linters     – { filetype = { "linter", ... } }               (table, or {})
--   formatters  – { filetype = { "fmt", ... } }                  (table, or {})
--   dap         – { adapters = {"name"}, setup = function() end } (table, or {})
--
-- Mason tools are auto-derived from linters + formatters. Tools not found
-- in the mason registry (e.g. ships with a toolchain) are silently skipped.

--- Apply identical config to several filetypes.
local function for_filetypes(filetypes, config)
	local t = {}
	for _, ft in ipairs(filetypes) do
		t[ft] = config
	end
	return t
end

---------------------------------------------------------------------------
-- Language definitions
---------------------------------------------------------------------------

local prettier = { "prettierd", "prettier", stop_after_first = true }

local languages = {
	core = {
		treesitter = { "lua", "vim", "vimdoc", "query", "regex", "markdown", "markdown_inline" },
		lsp = {
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			},
		},
		linters = {},
		formatters = {
			lua = { "stylua" },
		},
		dap = {},
	},

	go = {
		treesitter = { "go", "gomod", "gowork", "gosum" },
		lsp = {
			gopls = {
				settings = { gopls = { directoryFilters = { "-mocks" } } },
			},
		},
		linters = {
			go = { "golangcilint" },
		},
		formatters = {
			go = { "gofumpt", "goimports" },
		},
		dap = {
			adapters = { "delve" },
			setup = function()
				pcall(function()
					require("dap-go").setup()
				end)
			end,
		},
	},

	rust = {
		treesitter = { "rust" },
		lsp = {
			rust_analyzer = {
				settings = {
					["rust-analyzer"] = {
						cargo = { loadOutDirsFromCheck = true },
						procMacro = { enable = true },
						check = { command = "clippy" },
					},
				},
			},
		},
		linters = {},
		formatters = {
			rust = { "rustfmt" },
		},
		dap = {
			adapters = { "codelldb" },
		},
	},

	web = {
		treesitter = {
			"javascript", "typescript", "tsx",
			"json", "jsonc", "yaml", "toml",
			"html", "css", "scss", "svelte",
		},
		lsp = {
			vtsls = {},
			html = {},
			cssls = {},
			tailwindcss = {},
			svelte = {
				settings = {
					svelte = {
						plugin = {
							svelte = { defaultScriptLanguage = "ts" },
						},
					},
				},
			},
		},
		linters = for_filetypes(
			{ "javascript", "typescript", "javascriptreact", "typescriptreact" },
			{ "eslint_d" }
		),
		formatters = for_filetypes(
			{ "javascript", "typescript", "javascriptreact", "typescriptreact", "html", "css", "json", "yaml" },
			prettier
		),
		dap = {
			adapters = { "js-debug-adapter" },
			setup = function(dap)
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
	},

	shell = {
		treesitter = { "bash" },
		lsp = {
			bashls = {},
		},
		linters = {
			sh = { "shellcheck" },
		},
		formatters = {
			sh = { "shfmt" },
		},
		dap = {},
	},

	infra = {
		treesitter = { "proto", "terraform", "hcl", "sql", "dockerfile" },
		lsp = {
			terraformls = {},
			buf_ls = {},
			dockerls = {},
		},
		linters = {
			dockerfile = { "hadolint" },
			proto = { "buf_lint" },
		},
		formatters = {
			proto = { "buf" },
		},
		dap = {},
	},
}

---------------------------------------------------------------------------
-- Helpers: derive plugin-specific config from the table above
---------------------------------------------------------------------------

local M = {}

--- Raw language table for direct access.
M.languages = languages

--- Flat list of treesitter parser names.
function M.treesitter_parsers()
	local seen, list = {}, {}
	for _, lang in pairs(languages) do
		for _, p in ipairs(lang.treesitter) do
			if not seen[p] then
				seen[p] = true
				list[#list + 1] = p
			end
		end
	end
	return list
end

--- List of LSP server names (for mason-lspconfig ensure_installed).
function M.lsp_servers()
	local seen, list = {}, {}
	for _, lang in pairs(languages) do
		for server in pairs(lang.lsp) do
			if not seen[server] then
				seen[server] = true
				list[#list + 1] = server
			end
		end
	end
	return list
end

--- Table of { server_name = config } for servers with non-default settings.
function M.lsp_configs()
	local configs = {}
	for _, lang in pairs(languages) do
		for server, cfg in pairs(lang.lsp) do
			if next(cfg) then
				configs[server] = cfg
			end
		end
	end
	return configs
end

--- Flat list of mason tool names, auto-derived from linters + formatters.
--- Tools not found in the mason registry are silently skipped.
function M.mason_tools()
	local ok, registry = pcall(require, "mason-registry")
	if not ok then
		return {}
	end
	local seen, list = {}, {}
	local function add(name)
		if seen[name] then
			return
		end
		-- Try the name as-is, then with underscores replaced by hyphens.
		for _, candidate in ipairs({ name, name:gsub("_", "-") }) do
			if registry.has_package(candidate) then
				seen[name] = true
				list[#list + 1] = candidate
				return
			end
		end
	end
	for _, lang in pairs(languages) do
		for _, linters in pairs(lang.linters) do
			for _, l in ipairs(linters) do
				add(l)
			end
		end
		for _, fmts in pairs(lang.formatters) do
			for _, f in ipairs(fmts) do
				add(f)
			end
		end
	end
	return list
end

--- Merged linters_by_ft for nvim-lint.
function M.linters_by_ft()
	local result = {}
	for _, lang in pairs(languages) do
		for ft, linters in pairs(lang.linters) do
			result[ft] = linters
		end
	end
	return result
end

--- Merged formatters_by_ft for conform.nvim.
function M.formatters_by_ft()
	local result = {}
	for _, lang in pairs(languages) do
		for ft, fmts in pairs(lang.formatters) do
			result[ft] = fmts
		end
	end
	return result
end

--- List of DAP adapter names (for mason-nvim-dap ensure_installed).
function M.dap_adapters()
	local seen, list = {}, {}
	for _, lang in pairs(languages) do
		for _, a in ipairs(lang.dap.adapters or {}) do
			if not seen[a] then
				seen[a] = true
				list[#list + 1] = a
			end
		end
	end
	return list
end

--- Run all language-specific DAP setup functions.
function M.setup_dap(dap)
	for _, lang in pairs(languages) do
		if lang.dap.setup then
			lang.dap.setup(dap)
		end
	end
end

return M
