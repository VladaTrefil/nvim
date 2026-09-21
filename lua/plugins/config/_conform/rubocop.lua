local function server_argument()
	local output = vim.fn.system('bundle exec rubocop --server --version')

	if not output:match('--server') then
		return '--server'
	else
		return nil
	end
end

-- TODO: Add ignorelist for projects with incompatible rubocop config
local function config_path()
	if vim.fn.filereadable(vim.fn.getcwd() .. '/.rubocop.yml') == 1 then
		return vim.fn.getcwd() .. '/.rubocop.yml'
	end

	local config = vim.fn.fnamemodify(vim.fn.stdpath('config'), ':h') .. '/rubocop/rubocop.yml'
	if vim.fn.filereadable(config) == 1 then
		return config
	end
end

local function condition()
	return vim.fn.executable('bundle') > 0
end

-- print(table.concat({
-- 	'exec',
-- 	'rubocop',
-- 	'-a',
-- 	'-f',
-- 	'quiet',
-- 	'--force-exclusion',
-- 	'--config',
-- 	config_path(),
-- 	server_argument(),
-- 	'--stderr',
-- 	'--stdin',
-- 	'$FILENAME',
-- }, ' '))

local config = config_path()

return {
	command = 'bundle',
	args = vim.list_extend({
		'exec',
		'rubocop',
		'--autocorrect',
		'--format',
		'quiet',
		'--force-exclusion',
		-- server_argument(),
		-- '--server',
		'--stderr',
		'--stdin',
		'$FILENAME',
	}, config and { '--config', config } or {}),
	condition = condition,
	exit_codes = { 0, 1 },
}
