-- Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
-- Github: @aymericbeaumet/dotfiles
-- Entry point: load config and plugins

vim.loader.enable()

require("config.options")
require("config.keymaps")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

require("lazy").setup(require("plugins"))
