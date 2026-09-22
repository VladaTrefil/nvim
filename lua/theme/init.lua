local M = {}

-- Clear defaults only on initial loading, before plugins define their highlights.
vim.cmd('highlight clear')

if vim.fn.exists('syntax_on') then
	vim.cmd('syntax reset')
end

local utils = require('core.utils')

local highlight_groups = {
	base = { 'base', 'highlight_groups' },
	syntax = {
		'base',
		'lua',
		'vim',
		'javascript',
		'java',
		'json',
		'ruby',
		'xml',
		'css',
		'html',
		'markdown',
		'rasi',
	},
}

local applying = false

function M.apply()
	-- Changing 'background' can reload a colorscheme and re-enter this function.
	if applying then
		return
	end
	applying = true

	-- Avoid OptionSet callbacks in plugins when these values already match.
	if vim.o.background ~= 'dark' then
		vim.o.background = 'dark'
	end
	if not vim.o.termguicolors then
		vim.o.termguicolors = true
	end

	-- Reapply our definitions without clearing highlights owned by plugins.
	for _, module in ipairs(highlight_groups.base) do
		utils.set_highlights(require('theme.' .. module))
	end

	for _, module in ipairs(highlight_groups.syntax) do
		utils.set_highlights(require('theme.syntax.' .. module))
	end

	applying = false
end

local group = vim.api.nvim_create_augroup('NvimTheme', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
	group = group,
	-- Lazy's install colorscheme runs before plugin config needs groups like Bg2.
	callback = M.apply,
})
vim.api.nvim_create_autocmd('User', {
	group = group,
	pattern = 'LazyDone',
	-- Restore the theme after startup too, without erasing plugin highlights.
	callback = M.apply,
})

M.apply()

return M
