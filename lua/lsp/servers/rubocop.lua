local util = require('lspconfig.util')
local config = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h') .. '/rubocop/rubocop.yml'
local cmd = { 'bundle', 'exec', 'rubocop', '--lsp' }

if vim.fn.filereadable(config) == 1 then
	vim.list_extend(cmd, { '--config', config })
end

return {
	cmd = cmd,
	init_options = {
		enableProfileLoading = false,
	},
	root_dir = util.root_pattern('Gemfile', '.git'),
}
