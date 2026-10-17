vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd('filetype indent on')
vim.cmd('syntax enable')

local failures = {}

local function check(condition, message)
	if not condition then
		table.insert(failures, message)
	end
end

local scratch = vim.fn.tempname()
vim.fn.mkdir(scratch, 'p')
local xml_path = scratch .. '/sample.xml'
local compact_xml = '<root><child>text</child></root>'
vim.fn.writefile({ compact_xml }, xml_path)

require('core.autocmds')
vim.cmd.edit(vim.fn.fnameescape(xml_path))

check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { compact_xml }),
	'opening XML must not change its contents'
)
check(not vim.bo.modified, 'opening XML must leave the buffer unmodified')

require('core.global_cmds')
if vim.fn.exists(':FormatXML') ~= 2 then
	table.insert(failures, ':FormatXML must exist')
else
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { compact_xml })
	vim.bo.shiftwidth = 2
	vim.bo.expandtab = true
	vim.cmd.FormatXML()
	local formatted_xml = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	check(
		vim.deep_equal(formatted_xml, {
			'<root>',
			'  <child>text</child>',
			'</root>',
		}),
		(':FormatXML must expand and indent XML before returning; got %s (filetype=%s, indentexpr=%s)'):format(
			vim.inspect(formatted_xml),
			vim.bo.filetype,
			vim.bo.indentexpr
		)
	)
end

assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: core XML formatting is explicit and synchronous')

local conform_options
package.loaded.conform = {
	setup = function(options)
		conform_options = options
	end,
}
package.loaded['conform.util'] = {
	root_file = function()
		return function()
			return nil
		end
	end,
}
require('plugins.config._conform')

local svg_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(svg_buf)
vim.bo[svg_buf].filetype = 'svg'
vim.bo[svg_buf].indentexpr = ''
vim.bo[svg_buf].cindent = true
vim.bo[svg_buf].shiftwidth = 2

local unindented = { 'if (enabled) {', 'render();', '}' }
local indented = { 'if (enabled) {', '  render();', '}' }
vim.api.nvim_buf_set_lines(svg_buf, 0, -1, false, unindented)

vim.g.disable_autoformat = false
vim.b[svg_buf].disable_autoformat = false
local format_options = conform_options.format_on_save(svg_buf)
check(
	vim.deep_equal(format_options, { timeout_ms = 3000, lsp_fallback = true }),
	'SVG must retain Conform options'
)
check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(svg_buf, 0, -1, false), indented),
	'Conform format_on_save must indent SVG before returning'
)

vim.api.nvim_buf_set_lines(svg_buf, 0, -1, false, unindented)
vim.g.disable_autoformat = true
check(
	conform_options.format_on_save(svg_buf) == false,
	'disabled autoformat must reject SVG formatting'
)
check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(svg_buf, 0, -1, false), unindented),
	'disabled autoformat must leave SVG unchanged'
)
vim.g.disable_autoformat = false

local conform_plugin
for _, plugin in ipairs(dofile('lua/plugins/plugin_list.lua')) do
	if type(plugin) == 'table' and plugin[1] == 'stevearc/conform.nvim' then
		conform_plugin = plugin
		break
	end
end
check(conform_plugin and conform_plugin.event == 'BufWritePre', 'Conform must load on BufWritePre')

assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: Conform owns synchronous SVG indentation')
