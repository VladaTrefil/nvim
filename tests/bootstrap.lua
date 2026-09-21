-- Keep plugin installation pinned without letting Lazy write the repository lockfile.
require('plugins.bootstrap')
local lock_lines = vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json')
local lock = vim.json.decode(table.concat(lock_lines, '\n'))
local output = vim.fn.system({
	'git', '-C', vim.fn.stdpath('data') .. '/lazy/lazy.nvim',
	'checkout', '--detach', lock['lazy.nvim'].commit,
})
assert(vim.v.shell_error == 0, output)
local lazy = require('lazy')
local setup = lazy.setup
local lockfile = vim.fn.stdpath('state') .. '/lazy-lock.json'
vim.fn.mkdir(vim.fn.stdpath('state'), 'p')
vim.fn.writefile(lock_lines, lockfile)

lazy.setup = function(opts)
	opts.lockfile = lockfile
	return setup(opts)
end
