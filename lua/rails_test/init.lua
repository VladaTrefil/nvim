local runner = require('rails_test.runner')
local parser = require('rails_test.parser')

local M = {}

local function handle_result(lines, exit_code)
	local items = parser.parse(lines)

	-- Exit != 0 with no parsed failures likely means a boot/syntax error.
	-- Surface the first 20 lines so the user sees something actionable.
	if #items == 0 and exit_code ~= 0 then
		for i = 1, math.min(20, #lines) do
			table.insert(items, { text = lines[i], type = 'E' })
		end
	end

	vim.fn.setqflist(items, 'r')

	if #items > 0 then
		vim.cmd('copen')
	else
		vim.notify('✓ tests passed')
	end
end

local function run(tail_args)
	if vim.fn.executable('bin/rails') ~= 1 then
		vim.notify('bin/rails not found in cwd', vim.log.levels.ERROR)
		return
	end

	local argv = { 'bin/rails', 'test' }
	for _, a in ipairs(tail_args) do
		table.insert(argv, a)
	end

	runner.start(argv, { on_exit = handle_result })
end

function M.run_nearest()
	local file = vim.fn.expand('%')
	local line = vim.fn.line('.')
	run({ file .. ':' .. line })
end

function M.run_file()
	run({ vim.fn.expand('%') })
end

function M.run_all()
	run({})
end

function M.is_running()
	return runner.is_running()
end

return M
