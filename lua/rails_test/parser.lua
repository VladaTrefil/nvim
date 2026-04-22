local M = {}

-- Parse minitest output lines → list of quickfix items.
-- Each item: { filename, lnum, text, type }.
function M.parse(lines)
	local items = {}
	local i = 1
	local n = #lines

	while i <= n do
		local line = lines[i]

		if line == 'Failure:' then
			local header = lines[i + 1] or ''
			local path, lnum = header:match('%[([^:%]]+):(%d+)%]')

			local msg = {}
			local j = i + 2
			while j <= n and lines[j] ~= '' do
				table.insert(msg, lines[j])
				j = j + 1
			end

			if path and lnum then
				table.insert(items, {
					filename = path,
					lnum = tonumber(lnum),
					text = #msg > 0 and (header .. ' | ' .. table.concat(msg, ' | ')) or header,
					type = 'E',
				})
			end

			i = j + 1
		elseif line == 'Error:' then
			local header = lines[i + 1] or ''
			local body = {}
			local j = i + 2
			while j <= n and lines[j] ~= '' do
				table.insert(body, lines[j])
				j = j + 1
			end

			local message = body[1] or ''
			local frames = {}
			for k = 2, #body do
				local fp, fl = body[k]:match('^%s+([^:]+):(%d+):')
				if fp and fl then
					table.insert(frames, { path = fp, lnum = tonumber(fl) })
				end
			end

			local primary
			for _, f in ipairs(frames) do
				if not f.path:match('^/') then
					primary = f
					break
				end
			end

			if primary then
				table.insert(items, {
					filename = primary.path,
					lnum = primary.lnum,
					text = message ~= '' and (header .. ' | ' .. message) or header,
					type = 'E',
				})
				for _, f in ipairs(frames) do
					if f ~= primary and vim.fn.filereadable(f.path) == 1 then -- skip primary; already emitted as 'E' above
						table.insert(items, {
							filename = f.path,
							lnum = f.lnum,
							text = f.path .. ':' .. f.lnum,
							type = 'W',
						})
					end
				end
			end

			i = j + 1
		else
			i = i + 1
		end
	end

	return items
end

return M
