-- Global keymaps (leader is set in config/options.lua)

-- <CR> = save only in normal file buffers (not quickfix, help, etc.)
vim.api.nvim_create_autocmd("BufWinEnter", {
	callback = function(args)
		if vim.bo[args.buf].buftype == "" then
			vim.keymap.set("n", "<cr>", "<cmd>w<cr>", { buffer = args.buf, silent = true, desc = "Save buffer" })
		end
	end,
})

for _, mapping in ipairs({
	{ "n", "gl", vim.diagnostic.open_float, desc = "Show diagnostic float" },
	{
		"n",
		"[d",
		function()
			vim.diagnostic.jump({ count = -1 })
			vim.cmd("normal! zz")
		end,
		desc = "Previous diagnostic",
	},
	{
		"n",
		"]d",
		function()
			vim.diagnostic.jump({ count = 1 })
			vim.cmd("normal! zz")
		end,
		desc = "Next diagnostic",
	},
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
	{ "n", "<c-o>", "<c-o>zz", desc = "Jump back (centered)" },
	{ "n", "n", "nzz", desc = "Next search result (centered)" },
	{ "n", "N", "Nzz", desc = "Prev search result (centered)" },
	{ "n", "<c-w><bs>", "<c-w>h", desc = "Go to left window" },
	{ "t", "<c-w><bs>", "<Cmd>wincmd h<CR>", desc = "Go to left window" },
	{ "t", "<c-w>h", "<Cmd>wincmd h<CR>", desc = "Go to left window" },
	{ "t", "<c-w>j", "<Cmd>wincmd j<CR>", desc = "Go to below window" },
	{ "t", "<c-w>k", "<Cmd>wincmd k<CR>", desc = "Go to above window" },
	{ "t", "<c-w>l", "<Cmd>wincmd l<CR>", desc = "Go to right window" },
	{ "t", "<c-w>w", "<Cmd>wincmd w<CR>", desc = "Next window" },
	{ "t", "<c-w>W", "<Cmd>wincmd W<CR>", desc = "Previous window" },
	{ "t", "<c-w>p", "<Cmd>wincmd p<CR>", desc = "Last accessed window" },
	{ "t", "<c-w>s", "<Cmd>wincmd s | enew<CR>", desc = "Split horizontally" },
	{ "t", "<c-w><c-s>", "<Cmd>wincmd s | enew<CR>", desc = "Split horizontally" },
	{ "t", "<c-w>v", "<Cmd>wincmd v | enew<CR>", desc = "Split vertically" },
	{ "t", "<c-w><c-v>", "<Cmd>wincmd v | enew<CR>", desc = "Split vertically" },
	{ "t", "<c-w>n", "<Cmd>wincmd n<CR>", desc = "New window" },
	{ "t", "<c-w>c", "<Cmd>wincmd c<CR>", desc = "Close window" },
	{ "t", "<c-w>q", "<Cmd>wincmd q<CR>", desc = "Quit window" },
	{ "t", "<c-w>o", "<Cmd>wincmd o<CR>", desc = "Close other windows" },
	{ "t", "<c-w>T", "<Cmd>wincmd T<CR>", desc = "Move to new tab" },
	{ "t", "<c-w>r", "<Cmd>wincmd r<CR>", desc = "Rotate downward" },
	{ "t", "<c-w>R", "<Cmd>wincmd R<CR>", desc = "Rotate upward" },
	{ "t", "<c-w>x", "<Cmd>wincmd x<CR>", desc = "Exchange with next" },
	{ "t", "<c-w>H", "<Cmd>wincmd H<CR>", desc = "Move window far left" },
	{ "t", "<c-w>J", "<Cmd>wincmd J<CR>", desc = "Move window far bottom" },
	{ "t", "<c-w>K", "<Cmd>wincmd K<CR>", desc = "Move window far top" },
	{ "t", "<c-w>L", "<Cmd>wincmd L<CR>", desc = "Move window far right" },
	{ "t", "<c-w>=", "<Cmd>wincmd =<CR>", desc = "Equalize windows" },
	{ "t", "<c-w>_", "<Cmd>wincmd _<CR>", desc = "Maximize height" },
	{ "t", "<c-w>|", "<Cmd>wincmd |<CR>", desc = "Maximize width" },
	{ "t", "<c-w>+", "<Cmd>wincmd +<CR>", desc = "Increase height" },
	{ "t", "<c-w>-", "<Cmd>wincmd -<CR>", desc = "Decrease height" },
	{ "t", "<c-w>>", "<Cmd>wincmd ><CR>", desc = "Increase width" },
	{ "t", "<c-w><", "<Cmd>wincmd <<CR>", desc = "Decrease width" },
}) do
	vim.keymap.set(mapping[1], mapping[2], mapping[3], { noremap = true, silent = true, desc = mapping.desc })
end
