local root = require('conform.util').root_file({ '.git' })
local args = {}
local config = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h') .. '/stylua/stylua.toml'

-- Use global config if local config does not exist
if vim.fn.filereadable(vim.fn.getcwd() .. '/stylua.toml') == 0 and vim.fn.filereadable(config) == 1 then
	args = vim.list_extend(args, {
		'--config-path',
		config,
	})
end

return {
	prepend_args = args,
	cwd = root,
}
