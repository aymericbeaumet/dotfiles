-- Options: cursor, indentation, interface, safety, search, built-in plugin disables

-- cursor
vim.o.scroll = 10
vim.o.scrolloff = 10
vim.o.sidescrolloff = 10
vim.o.virtualedit = "block"

-- indentation
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.smarttab = true
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.textwidth = 80
vim.o.autoindent = true

-- interface
vim.o.mouse = "a"
vim.o.mousemodel = "extend"
vim.o.number = true
vim.o.relativenumber = false
vim.o.signcolumn = "number"
vim.o.shortmess = "AaoOsIctF"
vim.o.showtabline = 0
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.cursorline = true
vim.o.showmode = false
vim.o.termguicolors = true
vim.o.laststatus = 3

-- safety net
vim.o.undofile = true
vim.o.updatetime = 300

-- search and replace
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.wildignorecase = true
vim.opt.wildignore = {
	"*.o", "*.obj", "*.so", "*.a", "*.dylib", "*.pyc", "*.hi",
	"*.zip", "*.gz", "*.xz", "*.tar", "*.rar",
	"*/.git/*", "*/.hg/*", "*/.svn/*",
	"*.png", "*.jpg", "*.jpeg", "*.gif",
	"*.pdf", "*.dmg",
	".*.sw*", "*~",
	".DS_Store",
}

-- leader and timeout
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.o.timeout = true
vim.o.timeoutlen = 300
vim.o.ttimeoutlen = 0

-- Disable unused built-in plugins for faster startup
for _, plugin in ipairs({
	"2html_plugin", "getscript", "getscriptPlugin", "gzip", "logipat",
	"netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers", "matchit",
	"tar", "tarPlugin", "rrhelper", "spellfile_plugin", "vimball", "vimballPlugin",
	"zip", "zipPlugin", "tutor", "rplugin", "synmenu", "optwin", "compiler", "bugreport",
}) do
	vim.g["loaded_" .. plugin] = 1
end
