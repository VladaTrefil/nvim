local M = {}
local config_names = {
	'.stylelintrc',
	'.stylelintrc.json',
	'.stylelintrc.yaml',
	'.stylelintrc.yml',
	'.stylelintrc.js',
	'.stylelintrc.cjs',
	'.stylelintrc.mjs',
	'stylelint.config.js',
	'stylelint.config.cjs',
	'stylelint.config.mjs',
	'stylelint.config.ts',
	'stylelint.config.cts',
	'stylelint.config.mts',
}

local function project_config(filename)
	local directory = vim.fn.fnamemodify(filename, ':p:h')
	while directory do
		for _, name in ipairs(config_names) do
			if vim.fn.filereadable(directory .. '/' .. name) == 1 then
				return true
			end
		end
		local package = directory .. '/package.json'
		if vim.fn.filereadable(package) == 1 then
			local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(package), '\n'))
			if ok and type(data) == 'table' and data.stylelint ~= nil then
				return true
			end
		end
		local parent = vim.fs.dirname(directory)
		if parent == directory then
			break
		end
		directory = parent
	end
	return false
end

function M.args(filename)
	local config = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h')
		.. '/stylelint/stylelintrc.json'
	if project_config(filename) or vim.fn.filereadable(config) ~= 1 then
		return {}
	end
	-- Resolve for each invocation: changing the project/runtime must not retain
	-- a path cached from a previous asdf Node selection. No shell interpolation.
	local result = vim.system({ 'npm', 'root', '-g' }, { text = true }):wait()
	assert(result.code == 0, 'npm root -g failed: ' .. (result.stderr or ''))
	local basedir = vim.trim(result.stdout or '')
	assert(basedir ~= '', 'npm root -g returned no resolution directory')
	return { '--config', config, '--config-basedir', basedir }
end

return M
