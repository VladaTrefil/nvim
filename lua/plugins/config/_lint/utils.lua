local M = {}

local lint = require('lint')

M.setup_linters = function(linters)
	for name, data in pairs(linters) do
		local linter = lint.linters[name] or {}

		linter.cmd = data.cmd or linter.cmd
		linter.args = data.args or linter.args
		linter.stdin = data.stdin or linter.stdin
		linter.ignore_exitcode = data.ignore_exitcode or linter.ignore_exitcode
		linter.parser = data.parser or linter.parser

		if type(data.args) == 'function' then
			lint.linters[name] = function()
				local resolved = vim.deepcopy(linter)
				local cmd = type(resolved.cmd) == 'function' and resolved.cmd() or resolved.cmd
				resolved.args = vim.fn.executable(cmd) == 1 and data.args() or {}
				return resolved
			end
		else
			lint.linters[name] = linter
		end
	end
end

M.exec_lint = function(engine)
	-- Use nvim-lint's logic first:
	-- * checks if linters exist for the full filetype first
	-- * otherwise will split filetype by "." and add all those linters
	-- * this differs from conform.nvim which only uses the first filetype that has a formatter
	local names = engine.linters_by_ft[vim.bo.filetype] or {}
	names = engine._resolve_linter_by_ft(vim.bo.filetype)

	-- Add fallback linters.
	if #names == 0 then
		vim.list_extend(names, engine.linters_by_ft['_'] or {})
	end

	-- Add global linters.
	if engine.linters_by_ft['*'] then
		for _, linter in ipairs(engine.linters_by_ft['*']) do
			if not vim.tbl_contains(names, linter) then
				table.insert(names, linter)
			end
		end
	end

	-- Skip unavailable executables before nvim-lint tries to spawn them.
	local ctx = { filename = vim.api.nvim_buf_get_name(0) }
	ctx.dirname = vim.fn.fnamemodify(ctx.filename, ':h')
	names = vim.tbl_filter(function(name)
		local linter = engine.linters[name]
		if type(linter) == 'function' then
			linter = linter()
		end

		if type(linter) ~= 'table' then
			return false
		end

		local cmd = type(linter.cmd) == 'function' and linter.cmd() or linter.cmd

		return type(cmd) == 'string'
			and vim.fn.executable(cmd) == 1
			and (not linter.condition or linter.condition(ctx))
	end, names)

	-- Run linters.
	if #names > 0 then
		engine.try_lint(names)
	end
end

M.debounce = function(ms, fn)
	local timer = vim.loop.new_timer()
	return function(...)
		local argv = { ... }
		timer:start(ms, 0, function()
			timer:stop()
			vim.schedule_wrap(fn)(unpack(argv))
		end)
	end
end

return M
