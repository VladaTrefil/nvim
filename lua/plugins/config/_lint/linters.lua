local linters = {}
local config_home = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h')

-- TODO: fix standardjs linter parser function
-- linters.standardjs = require('plugins.config._lint.standardjs')

linters.rubocop = require('plugins.config._lint.rubocop')

linters.slimlint = require('plugins.config._lint.slimlint')

linters.shellcheck = {
	args = {
		'--format',
		'json',
		'-',
	},
}

linters.stylelint = {
	args = function()
		local filename = vim.fn.expand('%:p')
		return vim.list_extend(
			{ '-f', 'json', '--stdin', '--stdin-filename', filename },
			require('plugins.config.stylelint').args(filename)
		)
	end,
}

linters.codespell = {
	args = {
		'--regex',
		"(?<![a-z])[a-z'`]+|[A-Z][a-z'`]*|[a-z]+'[a-z]*|[a-z]+(?=[_-])|[a-z]+(?=[A-Z])|\\d+",
		function()
			return vim.fn.expand('%:p')
		end,
	},
}

local codespell_config = config_home .. '/codespell/codespellrc'
if vim.fn.filereadable(codespell_config) == 1 then
	vim.list_extend(linters.codespell.args, { '--config', codespell_config })
end

local function get_python_lint_cmd(linter_name)
	local local_cmd = vim.fn.fnamemodify('./.venv/bin/' .. linter_name, ':p')
	local stat = vim.loop.fs_stat(local_cmd)

	if stat then
		return local_cmd
	end

	return linter_name
end

linters.pylint = {
	cmd = get_python_lint_cmd('pylint'),
}

linters.mypy = {
	cmd = get_python_lint_cmd('mypy'),
}

return linters
