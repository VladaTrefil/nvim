local runner = require('rails_test.runner')
local parser = require('rails_test.parser')

local M = {}

local MODULE_TAG = 'rails_test'

-- Resolve a quickfix item's filename to an absolute path, or '' if unknown.
local function item_abspath(item)
	local name = item.bufnr and item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ''
	if name == '' then
		return ''
	end
	return vim.fn.fnamemodify(name, ':p')
end

-- Merge `new_items` into the quickfix list, removing prior rails_test items
-- within `scope`. scope == nil means all rails_test items are dropped.
-- Non-rails_test items are always preserved.
local function merge_qflist(new_items, scope)
	local merged = {}
	for _, item in ipairs(vim.fn.getqflist()) do
		local is_ours = item.module == MODULE_TAG
		if not is_ours then
			table.insert(merged, item)
		elseif scope and item_abspath(item) ~= scope then
			table.insert(merged, item)
		end
	end
	for _, item in ipairs(new_items) do
		table.insert(merged, item)
	end
	return merged
end

local function handle_result(lines, exit_code, scope)
	local items = parser.parse(lines)

	-- Exit != 0 with no parsed failures likely means a boot/syntax error.
	-- Surface the first 20 lines so the user sees something actionable.
	if #items == 0 and exit_code ~= 0 then
		for i = 1, math.min(20, #lines) do
			table.insert(items, { text = lines[i], type = 'E' })
		end
	end

	for _, item in ipairs(items) do
		item.module = MODULE_TAG
	end

	vim.fn.setqflist(merge_qflist(items, scope), 'r')

	if #items > 0 then
		vim.cmd('copen')
	else
		vim.notify('✓ tests passed')
	end
end

local function run(tail_args, scope)
	if vim.fn.executable('bin/rails') ~= 1 then
		vim.notify('bin/rails not found in cwd', vim.log.levels.ERROR)
		return
	end

	local argv = { 'bin/rails', 'test' }
	for _, a in ipairs(tail_args) do
		table.insert(argv, a)
	end

	runner.start(argv, {
		on_exit = function(lines, exit_code)
			handle_result(lines, exit_code, scope)
		end,
	})
end

-- Scope is an absolute filepath, or nil for "no scope / wipe all rails_test".
-- An empty expand('%:p') (unnamed buffer) is normalized to nil so we don't
-- key scope on ''.
local function current_file_scope()
	local p = vim.fn.expand('%:p')
	if p == '' then
		return nil
	end
	return p
end

function M.run_nearest()
	local relfile = vim.fn.expand('%')
	local line = vim.fn.line('.')
	run({ relfile .. ':' .. line }, current_file_scope())
end

function M.run_file()
	local relfile = vim.fn.expand('%')
	run({ relfile }, current_file_scope())
end

function M.run_all()
	run({}, nil)
end

function M.is_running()
	return runner.is_running()
end

return M
