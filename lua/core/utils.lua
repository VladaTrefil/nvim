local M = {}

local statuscolumn = require('core.ui.statuscolumn')

local fn = vim.fn
local merge_tb = vim.tbl_deep_extend

-- makes string safe for nvim commands
M.termcodes = function(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- Capitalizes first letter of string
M.capitalize = function(str)
	return str:gsub('^%l', string.upper)
end

-- Truncate path segments
-- @param path string: The path to truncate
-- @param trunc_at number: The number of segments to keep
-- @param trunc_len number: The length of the truncated segments
-- @param max_len number: Maximum number of segments to show
-- return string: The truncated path
M.truncate_path = function(path, trunc_at, trunc_len, max_len)
	local path_ary = vim.fn.split(path, '/')
	local result = {}

	if #path_ary <= trunc_at then
		return path
	end

	for index, value in ipairs(path_ary) do
		local diff = #path_ary - index

		if diff < trunc_at then
			table.insert(result, value)
		elseif diff < max_len then
			table.insert(result, value:sub(1, trunc_len))
		end
	end

	return vim.fn.join(result, '/')
end

-- converts camelCase to snake_case and vice versa
M.convert_case = function(word)
	if word:find('[a-z][A-Z]') then
		return word:gsub('([a-z])([A-Z])', '%1_%2'):lower()
	elseif word:find('_[a-z]') then
		return word:gsub('(_)([a-z])', function(_, l)
			return l:upper()
		end)
	else
		return word
	end
end

-- Convert hex to rgb
M.hex2rgb = function(hex)
	local value = hex:gsub('#', '')
	return tonumber('0x' .. value:sub(1, 2)),
		tonumber('0x' .. value:sub(3, 4)),
		tonumber('0x' .. value:sub(5, 6))
end

-- Convert rgb to hex
M.rgb2hex = function(red, green, blue)
	return string.format('#%02x%02x%02x', red, green, blue)
end

M.set_highlights = function(highlights)
	for group, spec in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, spec)
	end
end

-- sets vim mappings from a table of mode/keybinds to commands
M.load_mappings = function(mapping_table, mapping_opt)
	for mode, mode_values in pairs(mapping_table) do
		if mode == 1 then
			mode = ''
		end

		for keybind, mapping_info in pairs(mode_values) do
			local opts = merge_tb('force', mapping_opt or {}, mapping_info.opts or {})
			local cmd = mapping_info[1]

			opts.desc = mapping_info[2]

			vim.keymap.set(mode, keybind, cmd, opts)
		end
	end
end

-- Builds a label for a folded section
-- @return string: The label
M.fold_label_text = function()
	local line = fn.getline(vim.v.foldstart)
	local text = fn.substitute(line, '#|"|-+|{+', '', '')

	local fold_size = vim.v.foldend - vim.v.foldstart
	local spacer_size = 96 - fn.len(text) - fn.len(fold_size)

	local spacer = fn['repeat']({ '.', spacer_size })

	return ' ' .. text .. spacer .. ' (' .. fold_size .. ' L)  '
end

M.trigger_event = function(event)
	vim.schedule(function()
		vim.api.nvim_exec_autocmds('User', { pattern = 'Custom' .. event })
	end)
end

M.notify = function(msg, log, opts)
	if pcall(require, 'notify') then
		local default_opts = {
			title = 'log',
			timeout = 1000,
			animate = false,
		}

		opts = merge_tb('force', default_opts, opts or {})
		log = log or vim.log.levels.INFO

		async.run(function()
			vim.notify.async(msg, log, opts)
		end, function() end)
	else
		vim.api.nvim_notify(msg, log, {})
	end
end

local function with_saved_view(bufnr, callback)
	if bufnr == nil or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end
	local is_current_buffer = bufnr == vim.api.nvim_get_current_buf()
	local view = is_current_buffer and vim.fn.winsaveview() or nil

	vim.api.nvim_buf_call(bufnr, callback)

	if view then
		vim.fn.winrestview(view)
	end
end

local function indent_buffer()
	vim.cmd.normal({ args = { 'gg=G' }, bang = true })
end

-- Auto indents an entire buffer synchronously.
M.autoindent = function(bufnr)
	with_saved_view(bufnr, indent_buffer)
end

M.format_xml = function(bufnr)
	with_saved_view(bufnr, function()
		vim.cmd([[%s/></>\r</ge]])
		indent_buffer()
	end)
end

-- Creates a directory if it doesn't exist
M.mkdir = function()
	local dir = fn.expand('<afile>:p:h')

	-- Create that directory (and its parents) if it doesn't exist yet
	if fn.isdirectory(dir) == 0 then
		fn.mkdir(dir, 'p')
	end
end

M.switch_case_line_under_cursor = function()
	local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
	local word = vim.fn.expand('<cword>')
	local word_start = vim.fn.matchstrpos(vim.fn.getline('.'), '\\k*\\%' .. (col + 1) .. 'c\\k*')[2]

	local word_with_converted_case = M.convert_case(word)

	vim.api.nvim_buf_set_text(
		0,
		line - 1,
		word_start,
		line - 1,
		word_start + #word,
		{ word_with_converted_case }
	)
end

M.convert_color_code = function(red, green, blue)
	vim.fn.feedkeys(M.termcodes('"9y'), 'nx')

	local selection = vim.fn.getreg('9')
	local value

	if selection:find('#') then
		red, green, blue = M.hex2rgb(selection)
		value = string.format('%s,%s,%s', red, green, blue)
	elseif selection:find(',') then
		red, green, blue = selection:match('(%d+),%s?(%d+),%s?(%d+)')
		value = M.rgb2hex(red, green, blue)
	else
		vim.notify('Invalid color code', vim.log.levels.ERROR, { title = 'Color Converter' })
		return
	end

	vim.fn.setreg('9', value)
	vim.fn.feedkeys(M.termcodes('gv"9p'), 'nx')
end

-- Clears neovim UI elements
M.clear_ui = function()
	-- clear search highlights
	vim.fn.feedkeys(M.termcodes('<cmd>noh<CR>'), 'nx')

	-- clear command line
	vim.fn.feedkeys(':', 'nx')

	-- dismiss any open notify messages
	vim.notify.dismiss({ pending = false, silent = false })
end

M.enable_ui = function()
	vim.opt.showtabline = 2
	vim.opt.laststatus = 3
	vim.opt.ruler = true
	statuscolumn.show()
end

M.disable_ui = function()
	vim.opt.showtabline = 0
	vim.opt.laststatus = 0
	vim.opt.ruler = false
	statuscolumn.hide()
end

-- @return number: The size of the file in kilobytes
M.filesize_kb = function()
	return vim.fn.getfsize(vim.fn.expand('%')) / 1024
end

return M
