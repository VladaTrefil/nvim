local autocmd = vim.api.nvim_create_autocmd
local opt = vim.opt

local utils = require('core.utils')

autocmd('BufWinEnter', {
	pattern = '*.snippets',
	callback = function()
		opt.foldmethod = 'marker'
		opt.foldlevel = 0
	end,
})

autocmd({ 'BufNewFile', 'BufRead' }, {
	pattern = '*.tsx,*.jsx',
	callback = function()
		opt.filetype = 'typescript.typescriptreact'
	end,
})

local refresh_group = vim.api.nvim_create_augroup('core_refresh', { clear = true })
autocmd({ 'FocusGained', 'BufEnter' }, {
	desc = 'Refresh buffer',
	group = refresh_group,
	pattern = '*',
	callback = function(args)
		-- Highlight vertical tab as error
		vim.api.nvim_command('match RedSign /\\%x0b/')

		if vim.bo[args.buf].buftype == '' then
			vim.cmd.checktime({ args = { tostring(args.buf) } })
		end
	end,
})

autocmd('BufWritePost', {
	pattern = vim.fn.stdpath('config') .. '/*',
	callback = function()
		vim.cmd.source(vim.env.MYVIMRC)
	end,
})

autocmd({ 'BufWritePre', 'FileWritePre' }, {
	desc = 'Auto mkdir for missing directory',
	pattern = '*',
	callback = function()
		utils.mkdir()
	end,
})

-- Toggle relative number when lose focus/insert mode
vim.api.nvim_create_augroup('numbertoggle', { clear = true })
autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'WinEnter' }, {
	desc = 'Toggle number on',
	pattern = '*',
	group = 'numbertoggle',
	callback = function()
		if opt.number:get() and vim.fn.mode() ~= 'i' then
			opt.rnu = true
		end
	end,
})
autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'WinLeave' }, {
	desc = 'Toggle number off',
	pattern = '*',
	group = 'numbertoggle',
	callback = function()
		if opt.number:get() then
			opt.rnu = false
		end
	end,
})

-- Syntax
autocmd({ 'BufRead', 'BufNewFile' }, {
	desc = 'Init rasi syntax',
	pattern = '*.rasi',
	callback = require('syntax.rasi'),
})

-- local function match_redundant_spaces()
--   vim.fn.matchadd('RedundantSpaces', '\\s\\+$')
-- end
--
-- vim.api.nvim_create_autocmd('BufWinEnter,InsertEnter,InsertLeave', {
--   desc = 'Match redundant spaces',
--   pattern = '*/*',
--   callback = match_redundant_spaces
-- })

-- Change unsupported filetypes to supported ones
autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = '*.txt',
	callback = function()
		vim.opt_local.filetype = 'help'
	end,
})

autocmd({ 'BufRead', 'BufNewFile' }, {
	pattern = '*.es6',
	callback = function()
		vim.opt_local.filetype = 'javascript'
	end,
})
