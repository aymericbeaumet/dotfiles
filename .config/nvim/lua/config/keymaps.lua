-- Global keymaps (leader is set in config/options.lua)

-- <CR> = save only in normal file buffers (not quickfix, help, etc.)
vim.api.nvim_create_autocmd("BufWinEnter", {
	callback = function(args)
		if vim.bo[args.buf].buftype == "" then
			vim.keymap.set("n", "<cr>", "<cmd>w<cr>", { buffer = args.buf, silent = true, desc = "Save buffer" })
		end
	end,
})

-- Auto-show diagnostic float on CursorHold
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
	end,
})

for _, mapping in ipairs({
	{ "n", "gl", vim.diagnostic.open_float, desc = "Show diagnostic float" },
	{ "n", "[d", function() vim.diagnostic.jump({ count = -1 }) vim.cmd("normal! zz") end, desc = "Previous diagnostic" },
	{ "n", "]d", function() vim.diagnostic.jump({ count = 1 }) vim.cmd("normal! zz") end, desc = "Next diagnostic" },
	{ "n", "j", "gj", desc = "Move down (display line)" },
	{ "v", "j", "gj", desc = "Move down (display line)" },
	{ "n", "k", "gk", desc = "Move up (display line)" },
	{ "v", "k", "gk", desc = "Move up (display line)" },
	{ "n", "Y", "y$", desc = "Yank to end of line" },
	{ "n", "J", "mZJ`Z", desc = "Join lines (keep cursor)" },
	{ "v", "<", "<gv", desc = "Indent left (reselect)" },
	{ "v", ">", ">gv", desc = "Indent right (reselect)" },
	{ "n", "<c-l>", "<cmd>nohl<cr>:redraw<cr>:checktime<cr><c-l>gjgk", desc = "Clear and reload" },
	{ "n", "'A", "<cmd>edit ~/.config/alacritty/alacritty.toml<cr>", desc = "Edit Alacritty config" },
	{ "n", "'B", "<cmd>edit ~/.dotfiles/Brewfile<cr>", desc = "Edit Brewfile" },
	{ "n", "'G", "<cmd>edit ~/.gitconfig<cr>", desc = "Edit gitconfig" },
	{ "n", "'K", "<cmd>edit ~/.config/karabiner/karabiner.json<cr>", desc = "Edit Karabiner config" },
	{ "n", "'S", "<cmd>edit ~/.dotfiles/setup.sh<cr>", desc = "Edit setup.sh" },
	{ "n", "'T", "<cmd>edit ~/.tmux.conf<cr>", desc = "Edit tmux.conf" },
	{ "n", "'V", "<cmd>edit ~/.config/nvim/init.lua<cr>", desc = "Edit nvim config" },
	{ "n", "'Z", "<cmd>edit ~/.zshrc<cr>", desc = "Edit zshrc" },
	{ "i", "<c-a>", "<Home>", desc = "Go to line start" },
	{ "i", "<c-b>", "<Left>", desc = "Move left" },
	{ "i", "<c-d>", "<Del>", desc = "Delete char" },
	{ "i", "<c-e>", "<End>", desc = "Go to line end" },
	{ "i", "<c-f>", "<Right>", desc = "Move right" },
	{ "v", "<cr>", ":<C-U>'<,'>w !squeeze -1 --url --open<cr><cr>", desc = "Open URLs with squeeze" },
	{ "n", "<c-w><bs>", "<c-w>h", desc = "Go to left window" },
	{ "n", "<c-o>", "<c-o>zz", desc = "Jump back (centered)" },
	{ "n", "n", "nzz", desc = "Next search result (centered)" },
	{ "n", "N", "Nzz", desc = "Prev search result (centered)" },
}) do
	vim.keymap.set(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true, desc = mapping.desc })
end
