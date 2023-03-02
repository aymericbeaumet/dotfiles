local notesDirectory = "~/notes/"

function askTopic()
	return vim.fn.input("Topic: "):gsub("^%s+", ""):gsub("(?:\\.md)?%s+$", ""):gsub("%s+", "-")
end

function createNoteWithoutDate(topic)
	return function()
		local t = filename or askTopic()
		if t == nil or t == "" then
			return
		end
		vim.cmd("e " .. notesDirectory .. t .. ".md")
	end
end

function createNoteWithDate(topic, delta)
	return function()
		local d = delta or 0
		local t = topic or askTopic()
		if t == nil or t == "" then
			return
		end
		vim.cmd("e " .. notesDirectory .. os.date("%Y-%m-%d-" .. t, os.time() + d) .. ".md")
	end
end

for _, mapping in ipairs({
	{ "nt", createNoteWithDate("daily", 24 * 60 * 60) }, -- tomorrow
	{ "nd", createNoteWithDate("daily") }, -- daily
	{ "ny", createNoteWithDate("daily", -24 * 60 * 60) }, -- yesterday
	{ "nc", createNoteWithDate() }, -- new note with date
	{ "nC", createNoteWithoutDate() }, -- new note without date
}) do
	vim.keymap.set("n", "<leader>" .. mapping[1], mapping[2], { noremap = true, silent = true })
end

vim.cmd([[
  command! -bang -nargs=? -complete=dir NotesFiles
      \ call fzf#vim#files(
      \   "~/notes",
      \   fzf#vim#with_preview({
      \     'source': 'fd --type file -e .md --strip-cwd-prefix',
      \     'options': ['--sort', '--layout=reverse', '--tac', '--prompt=Notes> '],
      \   }),
      \   <bang>0,
      \ )

  function! NotesRipgrep(query, fullscreen)
    let command_fmt = 'rg --glob "!.git" --column --line-number --no-heading --color=always --smart-case -- %s || true'
    let initial_command = printf(command_fmt, shellescape(a:query))
    let reload_command = printf(command_fmt, '{q}')
    call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview({
    \   'dir': '~/notes',
    \   'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command, '--delimiter=:', '--nth=4..', '--sort', '--tac', '--prompt=Notes> '],
    \ }), a:fullscreen)
  endfunction
  command! -nargs=* -bang NotesRipgrep call NotesRipgrep(<q-args>, <bang>0)
]])

vim.keymap.set("n", "<leader>nf", "<cmd>NotesFiles<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>nr", "<cmd>NotesRipgrep<cr>", { noremap = true, silent = true })
