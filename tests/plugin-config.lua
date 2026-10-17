vim.opt.runtimepath:prepend(vim.fn.getcwd())

local plugins = dofile('lua/plugins/plugin_list.lua')

local failures = {}
local function fail(message)
	table.insert(failures, message)
end

local proxy
proxy = setmetatable({}, {
	__index = function()
		return function()
			return proxy
		end
	end,
	__call = function()
		return proxy
	end,
})

local searchers = package.searchers or package.loaders

for _, plugin in ipairs(plugins) do
	if type(plugin) == 'table' and type(plugin.config) == 'function' then
		local modules = {}
		local function config_searcher(module)
			table.insert(modules, module)
			return function()
				return proxy
			end
		end

		table.insert(searchers, 1, config_searcher)
		local ok, error_message = pcall(plugin.config)
		table.remove(searchers, 1)
		for _, module in ipairs(modules) do
			package.loaded[module] = nil
		end

		if not ok then
			fail(('%s config callback raised: %s'):format(plugin[1], error_message))
		elseif #modules ~= 1 then
			fail(('%s config callback loaded %d modules'):format(plugin[1], #modules))
		elseif not modules[1]:match('^plugins%.config%._[%w_]+$') then
			fail(('%s config callback loaded %s'):format(plugin[1], modules[1]))
		end
	end
end

local treesitter
for _, plugin in ipairs(plugins) do
	if type(plugin) == 'table' and plugin[1] == 'nvim-treesitter/nvim-treesitter' then
		treesitter = plugin
		break
	end
end

local build_source = treesitter and debug.getinfo(treesitter.build, 'S').source or ''
if not build_source:match('/lua/plugins/config/_treesitter/build%.lua$') then
	fail('Treesitter build callback is not defined in plugins.config._treesitter.build')
end

assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: active plugin hooks use standalone underscore-prefixed config modules')
