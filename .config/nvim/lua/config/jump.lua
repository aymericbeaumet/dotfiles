local M = {}

function M.jump()
	local flash = require("flash")
	local function cancel()
		vim.api.nvim_input("<esc>")
		return false
	end
	local options = {
		search = {
			max_length = false,
			-- Only the first character is the search; subsequent keys select hints.
			mode = function(input)
				return "\\V" .. vim.fn.escape(vim.fn.strcharpart(input, 0, 1), "\\")
			end,
		},
		jump = { autojump = false },
		prompt = { enabled = false },
		actions = { ["<CR>"] = cancel, ["<BS>"] = cancel },
		label = {
			after = false,
			before = { 0, 0 },
			uppercase = false,
			format = function(opts)
				return {
					{ opts.match.label1, "FlashMatch" },
					{ opts.match.label2, "FlashLabel" },
				}
			end,
		},
	}

	flash.jump(vim.tbl_deep_extend("force", options, {
		labeler = function(matches, state)
			if state.pattern:empty() then
				return
			end
			local labels = state:labels()
			for index, match in ipairs(matches) do
				match.label1 = labels[math.floor((index - 1) / #labels) + 1]
				-- Leave excess matches unlabeled rather than reusing a pair.
				match.label2 = match.label1 and labels[(index - 1) % #labels + 1] or nil
				match.label = match.label1
			end
		end,
		action = function(match, state)
			local first_label = match.label1
			state:hide()
			flash.jump(vim.tbl_deep_extend("force", options, {
				highlight = { matches = false },
				matcher = function(win)
					return vim.tbl_filter(function(candidate)
						return candidate.label1 == first_label and candidate.win == win
					end, state.results)
				end,
				labeler = function(matches)
					for _, candidate in ipairs(matches) do
						candidate.label = candidate.label2
					end
				end,
			}))
		end,
	}))
end

return M
