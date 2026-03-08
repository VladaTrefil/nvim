local source = {}

local VARIABLE_FILE_PATHS = {
	'app/assets/stylesheets/_variables.sass',
	'app/assets/stylesheets/_variables-colors.sass',
	'app/assets/stylesheets/_variables.scss',
}

source.new = function()
	return setmetatable({ cache = {} }, { __index = source })
end

source.get_trigger_characters = function()
	return { '$' }
end

source.is_available = function()
	local ft = vim.bo.filetype
	return ft == 'sass' or ft == 'scss'
end

local function parse_variables(path)
	local items = {}

	if vim.fn.filereadable(path) ~= 1 then
		return items
	end

	local lines = vim.fn.readfile(path)
	for _, line in ipairs(lines) do
		local var_name = line:match('^%s*(%$[%w_-]+)%s*:')
		if var_name then
			table.insert(items, {
				label = var_name,
				kind = require('cmp.types').lsp.CompletionItemKind.Variable,
				documentation = line,
			})
		end
	end

	return items
end

source.complete = function(self, _, callback)
	local root = vim.fn.getcwd()
	local items = {}

	for _, relative_path in ipairs(VARIABLE_FILE_PATHS) do
		local full_path = root .. '/' .. relative_path

		local stat = vim.loop.fs_stat(full_path)
		if stat then
			local cache_key = full_path
			local cached = self.cache[cache_key]

			if cached and cached.mtime == stat.mtime.sec then
				vim.list_extend(items, cached.items)
			else
				local parsed = parse_variables(full_path)
				self.cache[cache_key] = { mtime = stat.mtime.sec, items = parsed }
				vim.list_extend(items, parsed)
			end
		end
	end

	callback({ items = items })
end

return source
