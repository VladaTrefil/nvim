-- Loaded before init.lua, after the pinned Lazy bootstrap. Observe real startup;
-- do not alter the plugin spec, install colorscheme, or theme application order.
local phase = vim.env.NVIM_THEME_PHASE
local function report(message)
	io.stdout:write('\n' .. message .. '\n')
	io.stdout:flush()
end
local events, errors = {}, {}
local util = require('lazy.core.util')
local original_error = util.error
util.error = function(message, opts)
	errors[#errors + 1] = type(message) == 'table' and table.concat(message, '\n')
		or tostring(message)
	return original_error(message, opts)
end

vim.api.nvim_create_autocmd('ColorScheme', {
	callback = function(event)
		events[#events + 1] = 'ColorScheme:' .. event.match
	end,
})
vim.api.nvim_create_autocmd('User', {
	pattern = { 'LazyInstallPre', 'LazyInstall', 'LazyDone', 'VeryLazy' },
	callback = function(event)
		events[#events + 1] = event.match
	end,
})

local groups = { 'Bg2', 'Normal', 'Comment', 'String', 'Function', 'DiagnosticError' }
local function snapshot()
	local result = {}
	for _, name in ipairs(groups) do
		result[name] = vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
		-- Neovim mirrors GUI attributes into cterm when none were supplied.
		result[name].cterm = nil
	end
	return result
end

local function check()
	report('THEME_PHASE ' .. phase)
	report('STARTUP_EVENTS ' .. table.concat(events, ' -> '))
	local actual = snapshot()
	for _, name in ipairs(groups) do
		report('HIGHLIGHT ' .. name .. ' ' .. vim.json.encode(actual[name]))
	end
	local colors_name = vim.g.colors_name or '<unset>'
	report('COLORS_NAME ' .. colors_name)
	report('LAZY_ERRORS ' .. #errors)
	for _, message in ipairs(errors) do
		report(message)
	end
	assert(#errors == 0, 'Lazy reported startup errors')
	assert(vim.v.errmsg == '', vim.v.errmsg)
	local config = require('lazy.core.config')
	local count = 0
	for name, plugin in pairs(config.plugins) do
		assert(plugin._.installed, 'Not installed: ' .. name)
		assert(not require('lazy.core.plugin').has_errors(plugin), 'Install failed: ' .. name)
		count = count + 1
	end
	report('INSTALLED_PLUGINS ' .. count)
	assert(vim.tbl_contains(events, 'LazyDone'), 'LazyDone was not observed')
	assert(
		vim.tbl_contains(events, 'LazyInstallPre') == (phase == 'first'),
		'Unexpected install state'
	)
	assert(package.loaded['plugins.config._indentline'], 'Indentline config did not complete')
	assert(colors_name ~= 'habamax', 'Lazy applied habamax during installation')

	local colors = require('theme.colors')
	local function rgb(value)
		return tonumber(value:sub(2), 16)
	end
	local expected = {
		Bg2 = { fg = rgb(colors.dark2) },
		Normal = { fg = rgb(colors.light0), bg = rgb(colors.dark0) },
		Comment = { fg = rgb(colors.gray), bg = rgb(colors.dark1), italic = true },
		String = { fg = rgb(colors.green), italic = true },
		Function = { fg = rgb(colors.bright_green), bold = true },
		DiagnosticError = { fg = rgb(colors.bright_red) },
	}
	assert(vim.deep_equal(actual, expected), 'Theme differs from the configured palette')
	report('PASS: first/second startup matches all six configured theme groups')

	-- Reapplication must preserve plugin-owned highlights and be idempotent.
	local all_before = vim.api.nvim_get_hl(0, {})
	local theme = require('theme')
	theme.apply()
	theme.apply()
	local all_after = vim.api.nvim_get_hl(0, {})
	for name, spec in pairs(all_after) do
		if not vim.deep_equal(all_before[name], spec) then
			report(
				'CHANGED '
					.. name
					.. ' '
					.. vim.inspect(all_before[name])
					.. ' -> '
					.. vim.inspect(spec)
			)
		end
	end
	assert(vim.deep_equal(all_before, all_after), 'apply() changed existing highlights')
	report('PASS: applying twice preserves every highlight, including plugin groups')

	-- Compare independent processes using the shared, isolated state directory.
	local statefile = vim.fn.stdpath('state') .. '/theme-first.json'
	local plugin_groups = { 'IndentBlanklineChar', 'IblScope', 'IblIndent' }
	local stable = snapshot()
	for _, name in ipairs(plugin_groups) do
		stable[name] = vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
		assert(next(stable[name]), 'Missing plugin group: ' .. name)
	end
	if phase == 'first' then
		vim.fn.writefile({ vim.json.encode(stable) }, statefile)
	else
		local first = vim.json.decode(table.concat(vim.fn.readfile(statefile), '\n'))
		assert(vim.deep_equal(first, stable), 'Second start differs from the first')
		report('PASS: first and second starts have identical theme and indent highlights')
	end

	vim.cmd.colorscheme('habamax')
	assert(vim.deep_equal(snapshot(), expected), 'ColorScheme did not restore the theme')
	report('PASS: ColorScheme restores the configured palette')
	vim.o.background = 'light'
	theme.apply()
	assert(
		vim.deep_equal(snapshot(), expected),
		'apply() after a background change did not restore the theme'
	)
	assert(vim.o.background == 'dark', 'Theme background was not restored')
	report('PASS: apply() after a background change restores the theme without recursion')

	vim.api.nvim_set_hl(0, 'Bg2', {})
	vim.api.nvim_exec_autocmds('User', { pattern = 'LazyDone', modeline = false })
	assert(vim.deep_equal(snapshot(), expected), 'LazyDone did not restore the theme')
	report('PASS: LazyDone restores a cleared theme group')
end

vim.api.nvim_create_autocmd('VimEnter', {
	once = true,
	callback = function()
		vim.schedule(function()
			local ok, err = xpcall(check, debug.traceback)
			if not ok then
				report('FAIL: ' .. err)
				vim.cmd('cquit 1')
			else
				vim.cmd('qa!')
			end
		end)
	end,
})
