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
	args = {
		'-f',
		'json',
		'--stdin',
		'--stdin-filename',
		function()
			return vim.fn.expand('%:p')
		end,
	},
}

local stylelint_config = config_home .. '/stylelint/stylelintrc.json'
if vim.fn.filereadable(stylelint_config) == 1 then
	vim.list_extend(linters.stylelint.args, { '--config', stylelint_config })
end

linters.codespell = {
	args = {
		'--regex',
		"(?<![a-z])[a-z'`]+|[A-Z][a-z'`]*|[a-z]+'[a-z]*|[a-z]+(?=[_-])|[a-z]+(?=[A-Z])|\\d+",
		function()
			return vim.fn.expand('%:p')
		end,
	},
}

for _, option in ipairs({
	{ '--ignore-words', 'ignore.txt' },
	{ '--exclude-file', 'exclude-file.txt' },
	{ '--config', 'codespellrc' },
}) do
	local path = config_home .. '/codespell/' .. option[2]
	if vim.fn.filereadable(path) == 1 then
		vim.list_extend(linters.codespell.args, { option[1], path })
	end
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
