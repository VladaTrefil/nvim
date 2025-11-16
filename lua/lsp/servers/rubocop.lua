local util = require('lspconfig.util')

return {
	cmd = {
		'bundle',
		'exec',
		'rubocop',
		'--lsp',
		'--config',
		vim.fn.expand('$XDG_CONFIG_HOME/rubocop/rubocop.yml'),
	},
	bundle_path = '~/.local/share/asdf/shims/bundle',
	init_options = {
		enableProfileLoading = false,
	},
	root_dir = util.root_pattern('Gemfile', '.git'),
}
