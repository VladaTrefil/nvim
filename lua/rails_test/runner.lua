local M = {
	running = false,
	_job = nil,
}

-- Start a Rails test job.
-- argv: string[] — command + args, e.g. { 'bin/rails', 'test', 'path:42' }.
-- opts.cwd: string — working directory (defaults to getcwd()).
-- opts.on_exit: fun(lines: string[], exit_code: number) — called once on completion.
function M.start(argv, opts)
	opts = opts or {}

	if M._job then
		vim.fn.jobstop(M._job)
		M._job = nil
	end

	local lines = {}
	local this_job

	local function collect(_, data)
		if not data then
			return
		end
		for _, ln in ipairs(data) do
			table.insert(lines, ln)
		end
	end

	this_job = vim.fn.jobstart(argv, {
		cwd = opts.cwd or vim.fn.getcwd(),
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = collect,
		on_stderr = collect,
		on_exit = function(_, exit_code)
			if this_job ~= M._job then
				return
			end
			M._job = nil
			M.running = false
			vim.cmd('redrawstatus')
			if opts.on_exit then
				opts.on_exit(lines, exit_code)
			end
		end,
	})

	M._job = this_job
	M.running = true
	vim.cmd('redrawstatus')
end

function M.is_running()
	return M.running
end

return M
