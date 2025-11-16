local linters = {}

linters.standardjs = require('plugins.config._lint.standardjs')

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
	args = {
		'--config',
		vim.fn.expand('$XDG_CONFIG_HOME/stylelint/stylelintrc.json'),
		'-f',
		'json',
		'--stdin',
		'--stdin-filename',
		function()
			return vim.fn.expand('%:p')
		end,
	},
}

linters.codespell = {
	args = {
		'--ignore-words',
		vim.fn.expand('$XDG_CONFIG_HOME/codespell/ignore.txt'),
		'--exclude-file',
		vim.fn.expand('$XDG_CONFIG_HOME/codespell/exclude-file.txt'),
		'--config',
		vim.fn.expand('$XDG_CONFIG_HOME/codespell/codespellrc'),
		'--regex',
		"(?<![a-z])[a-z'`]+|[A-Z][a-z'`]*|[a-z]+'[a-z]*|[a-z]+(?=[_-])|[a-z]+(?=[A-Z])|\\d+",
		function()
			return vim.fn.expand('%:p')
		end,
	},
}

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
