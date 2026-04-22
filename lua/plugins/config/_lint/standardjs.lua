local binary_name = 'standard'
local pattern = '[^:]+:(%d+):(%d+):([^%.]+%.?)%s%(([%a-]+)%)%s?%(?(%a*)%)?'
local groups = { 'lnum', 'col', 'message', 'code', 'severity' }
local severities = {
	[''] = vim.diagnostic.severity.ERROR,
	['warning'] = vim.diagnostic.severity.WARN,
}

return {
	-- parser = require('lint.parser').from_pattern(
	-- 	pattern,
	-- 	groups,
	-- 	severities,
	-- 	{ ['source'] = 'standardjs' },
	-- 	{}
	-- ),
	cmd = function()
		local local_binary = vim.fn.fnamemodify('./node_modules/.bin/' .. binary_name, ':p')
		return vim.loop.fs_stat(local_binary) and local_binary or binary_name
	end,
	stdin = true,
	args = { '--stdin' },
	ignore_exitcode = true,
	parser = function(output)
		local diagnostics = {}
		local decoded = vim.json.decode(output)
		print(decoded)

		-- exit if there are no diagnostic messages
		if not decoded or not decoded.files[1] then
			return diagnostics
		end

		local offences = decoded.files[1].offenses

		vim.notify(vim.inspect(offences))

		for _, off in pairs(offences) do
			table.insert(diagnostics, {
				source = 'standardjs',
				lnum = off.location.start_line - 1 or 0,
				col = off.location.start_column - 1,
				end_lnum = off.location.last_line - 1,
				end_col = off.location.last_column,
				severity = severities[off.severity],
				message = off.message,
				code = off.cop_name,
			})
		end

		return diagnostics
	end,
}
