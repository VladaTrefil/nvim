require('plugins.bootstrap')

local lazy_ok, lazy = pcall(require, 'lazy')

if not lazy_ok then
	vim.notify("Lazy.nvim doesn't exist")
	return
end

local plugins = require('plugins.plugin_list')

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
		-- lazy.nvim's sentinel for keeping the current highlights during installation
		colorscheme = { 'default' },
	},
})

vim.defer_fn(function()
	vim.api.nvim_exec_autocmds('User', { pattern = 'PackLoad' })
end, 10)
