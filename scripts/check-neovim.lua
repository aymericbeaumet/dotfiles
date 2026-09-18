local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root .. "/.config/nvim")

local failures = 0
local function test(name, callback)
	local ok, err = pcall(callback)
	if ok then
		print("PASS " .. name)
	else
		failures = failures + 1
		io.stderr:write("FAIL " .. name .. ": " .. tostring(err) .. "\n")
	end
end

local function equal(actual, expected)
	assert(vim.deep_equal(actual, expected), vim.inspect(actual) .. " ~= " .. vim.inspect(expected))
end

local registry_requested = false
package.preload["mason-registry"] = function()
	registry_requested = true
	error("Mason is not loaded during plugin specification construction")
end

local languages = require("config.languages")
local specs = require("plugins")
local function plugin(name)
	for _, spec in ipairs(specs) do
		if spec[1] == name then
			return spec
		end
	end
	error("Missing plugin: " .. name)
end

test("tool installation works before Mason loads", function()
	assert(not registry_requested, "package derivation requested mason-registry")
	equal(languages.mason_tools(), {
		"buf",
		"eslint_d",
		"gofumpt",
		"goimports",
		"golangci-lint",
		"hadolint",
		"prettier",
		"prettierd",
		"ruff",
		"shellcheck",
		"shfmt",
		"stylua",
		"taplo",
	})
end)

test("installer receives the complete deduplicated package list", function()
	local installer
	for _, dependency in ipairs(plugin("neovim/nvim-lspconfig").dependencies) do
		if type(dependency) == "table" and dependency[1] == "WhoIsSethDaniel/mason-tool-installer.nvim" then
			installer = dependency
		end
	end
	assert(installer, "missing tool installer")
	assert(#installer.opts.ensure_installed > 0, "empty installation list")
	equal(installer.opts.ensure_installed, languages.mason_tools())
end)

test("new tools require an explicit package ownership decision", function()
	local formatters = languages.languages.lua.formatters.lua
	formatters[#formatters + 1] = "unknown-formatter"
	local ok, err = pcall(languages.mason_tools)
	formatters[#formatters] = nil
	assert(not ok and tostring(err):find("unknown-formatter", 1, true), "unknown formatter was silently skipped")
end)

local linted_buffers = {}
package.loaded.lint = {
	try_lint = function()
		linted_buffers[#linted_buffers + 1] = vim.api.nvim_get_current_buf()
	end,
}
plugin("mfussenegger/nvim-lint").config()

local file = vim.api.nvim_create_buf(true, false)
local other_file = vim.api.nvim_create_buf(true, false)
vim.bo[file].filetype = "go"
vim.api.nvim_set_current_buf(other_file)

test("saving lints the saved buffer instead of the focused buffer", function()
	linted_buffers = {}
	vim.api.nvim_exec_autocmds("BufWritePost", { buffer = file })
	equal(linted_buffers, { file })
end)

test("leaving insert mode does not launch a linter", function()
	linted_buffers = {}
	vim.api.nvim_exec_autocmds("InsertLeave", { buffer = file })
	equal(linted_buffers, {})
end)

test("manual lint checks the current file", function()
	linted_buffers = {}
	vim.api.nvim_set_current_buf(file)
	vim.cmd("Lint")
	equal(linted_buffers, { file })
end)

test("large files skip saved and manual lint", function()
	linted_buffers = {}
	vim.b[file].large_file = true
	vim.api.nvim_exec_autocmds("BufWritePost", { buffer = file })
	vim.cmd("Lint")
	vim.b[file].large_file = nil
	equal(linted_buffers, {})
end)

test("non-file buffers skip saved and manual lint", function()
	linted_buffers = {}
	vim.bo[file].buftype = "nofile"
	vim.api.nvim_exec_autocmds("BufWritePost", { buffer = file })
	vim.cmd("Lint")
	vim.bo[file].buftype = ""
	equal(linted_buffers, {})
end)

if failures > 0 then
	error(("%d Neovim checks failed"):format(failures))
end
