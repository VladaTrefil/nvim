vim.opt.runtimepath:prepend(vim.fn.getcwd())
local config_home = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h')
vim.fn.mkdir(config_home .. '/stylelint', 'p')
vim.fn.writefile({ '{}' }, config_home .. '/stylelint/stylelintrc.json')
vim.fn.mkdir(config_home .. '/rubocop', 'p')
vim.fn.writefile({ 'AllCops: {}' }, config_home .. '/rubocop/config.yml')
vim.fn.mkdir(config_home .. '/codespell', 'p')
vim.fn.writefile({ '[codespell]' }, config_home .. '/codespell/codespellrc')
local scratch = vim.env.HOME .. '/scratch'
vim.fn.mkdir(scratch .. '/project/nested', 'p')
vim.cmd.cd(scratch)
local original_system = vim.system
local calls = 0
vim.system = function(command)
	assert(vim.deep_equal(command, { 'npm', 'root', '-g' }))
	calls = calls + 1
	return {
		wait = function()
			return { code = 0, stdout = '/runtime-' .. calls .. '/node_modules\n', stderr = '' }
		end,
	}
end
local stylelint = require('plugins.config.stylelint')
local args = stylelint.args(scratch .. '/outside.scss')
assert(args[1] == '--config' and args[3] == '--config-basedir')
assert(args[4] == '/runtime-1/node_modules')
assert(stylelint.args(scratch .. '/outside.sass')[4] == '/runtime-2/node_modules')
vim.fn.writefile({ '{}' }, scratch .. '/project/.stylelintrc.json')
assert(#stylelint.args(scratch .. '/project/nested/test.scss') == 0)
assert(calls == 2, 'project config must not query global npm')
vim.fn.delete(scratch .. '/project/.stylelintrc.json')
vim.fn.writefile({ '{"stylelint":{"rules":{}}}' }, scratch .. '/project/package.json')
assert(#stylelint.args(scratch .. '/project/nested/test.scss') == 0)
vim.system = original_system
local linters = require('plugins.config._lint.linters')
assert(type(linters.stylelint.args) == 'function')
local codespell = linters.codespell.args
assert(vim.tbl_contains(codespell, '--config'))
assert(not vim.tbl_contains(codespell, '--ignore-words'))
assert(not vim.tbl_contains(codespell, '--exclude-file'))
assert(vim.tbl_contains(linters.rubocop.args, config_home .. '/rubocop/config.yml'))
assert(
	vim.tbl_contains(
		require('plugins.config._conform.rubocop').args,
		config_home .. '/rubocop/config.yml'
	)
)
package.loaded.lint = { linters = { stylelint = { cmd = 'nvim', stdin = true } } }
local utils = require('plugins.config._lint.utils')
utils.setup_linters({ stylelint = {
	args = function()
		return { '--test' }
	end,
} })
assert(vim.deep_equal(package.loaded.lint.linters.stylelint().args, { '--test' }))
print(
	'PASS: dynamic Stylelint runtime resolution, project precedence, RuboCop rename and shared codespell rc'
)
