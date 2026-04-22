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
					text = header .. ' | ' .. table.concat(msg, ' | '),
					type = 'E',
				})
			end

			i = j + 1
		else
			i = i + 1
		end
	end

	return items
end

return M
