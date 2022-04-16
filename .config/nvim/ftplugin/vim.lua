-- reset <cr> to its original behavior in the vim edit command window
vim.api.nvim_buf_set_keymap(0, "n", "<cr>", "<cr>", { noremap = true, silent = true })
