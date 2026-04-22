local source = {}

local MIXIN_FILE_PATHS = {
	'app/assets/stylesheets/modules/bootstrap-overrides/mixins/_type.sass',
	'app/assets/stylesheets/_mixins.scss',
}

source.new = function()
	return setmetatable({ cache = {} }, { __index = source })
end

source.get_trigger_characters = function()
	return { '+' }
end

source.is_available = function()
	local ft = vim.bo.filetype
	return ft == 'sass' or ft == 'scss'
end

local function parse_mixins(path)
	local items = {}

	if vim.fn.filereadable(path) ~= 1 then
		return items
	end

	local lines = vim.fn.readfile(path)
	for _, line in ipairs(lines) do
		-- Match SASS mixin definitions: =mixin-name or @mixin mixin-name
		local mixin_name = line:match('^%s*=%s*([%w_-]+)') or line:match('^%s*@mixin%s+([%w_-]+)')
		if mixin_name then
			table.insert(items, {
				label = mixin_name,
				kind = require('cmp.types').lsp.CompletionItemKind.Function,
				documentation = line,
			})
		end
	end

	return items
end

source.complete = function(self, _, callback)
	local root = vim.fn.getcwd()
	local items = {}

	for _, relative_path in ipairs(MIXIN_FILE_PATHS) do
		local full_path = root .. '/' .. relative_path

		local stat = vim.loop.fs_stat(full_path)
		if stat then
			local cache_key = full_path
			local cached = self.cache[cache_key]

			if cached and cached.mtime == stat.mtime.sec then
				vim.list_extend(items, cached.items)
			else
				local parsed = parse_mixins(full_path)
				self.cache[cache_key] = { mtime = stat.mtime.sec, items = parsed }
				vim.list_extend(items, parsed)
			end
		end
	end

	callback({ items = items })
end

return source
