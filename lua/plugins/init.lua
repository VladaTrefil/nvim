require('plugins.bootstrap')

local lazy_ok, lazy = pcall(require, 'lazy')

if not lazy_ok then
	vim.notify("Lazy.nvim doesn't exist")
	return
end

local plugins = require('plugins.plugin_list')

-- add binaries installed by mason.nvim to path
vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath('data') .. '/mason/bin'

lazy.setup({
	spec = plugins,
	-- automatically check for plugin updates
	checker = { enabled = true },
	git = {
		timeout = 300,
		subcommands = {
			update = 'pull --rebase',
		},
	},
	install = {
		-- install missing plugins on startup. This doesn't increase startup time.
		missing = true,
		-- try to load one of these colorschemes when starting an installation during startup
		colorscheme = nil,
	},
})

vim.defer_fn(function()
	vim.api.nvim_exec_autocmds('User', { pattern = 'PackLoad' })
end, 10)
