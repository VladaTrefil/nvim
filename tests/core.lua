vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd('filetype indent on')
vim.cmd('syntax enable')
vim.o.report = 9999

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

local refresh_path = scratch .. '/refresh.txt'
vim.fn.writefile({ 'original' }, refresh_path)
vim.cmd.edit({ args = { refresh_path }, bang = true })
vim.o.autoread = true
vim.fn.writefile({ 'changed externally' }, refresh_path)
local future = os.time() + 2
vim.uv.fs_utime(refresh_path, future, future)
vim.api.nvim_exec_autocmds('FocusGained', {})
check(
	vim.api.nvim_get_current_line() == 'changed externally',
	'FocusGained must reload an externally changed file'
)

local nofile_buf = vim.api.nvim_create_buf(true, true)
vim.api.nvim_set_current_buf(nofile_buf)
vim.bo[nofile_buf].buftype = 'nofile'
vim.api.nvim_buf_set_lines(nofile_buf, 0, -1, false, { 'scratch content' })
local refresh_ok = pcall(vim.api.nvim_exec_autocmds, 'BufEnter', { buffer = nofile_buf })
check(refresh_ok, 'buffer refresh must ignore non-file buffers without errors')
check(
	vim.api.nvim_get_current_line() == 'scratch content',
	'buffer refresh must not alter non-file buffers'
)

local utils = require('core.utils')
local general_mappings = require('core.mappings').general
utils.load_mappings({
	n = {
		p = general_mappings.n.p,
		P = general_mappings.n.P,
	},
})

local function paste_buffer(filetype)
	local bufnr = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.bo[bufnr].filetype = filetype
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '  anchor' })
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	return bufnr
end

local function feedkeys(keys)
	vim.api.nvim_feedkeys(utils.termcodes(keys), 'mx', false)
end

vim.fn.setreg('a', { 'alpha', 'beta' }, 'V')
local paste_after_buf = paste_buffer('lua')
feedkeys('"a2p')
check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(paste_after_buf, 0, -1, false), {
		'  anchor',
		'  alpha',
		'  beta',
		'  alpha',
		'  beta',
	}),
	'paste after must preserve an explicit register and count while adjusting indentation'
)

local paste_before_buf = paste_buffer('lua')
feedkeys('"a2P')
check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(paste_before_buf, 0, -1, false), {
		'  alpha',
		'  beta',
		'  alpha',
		'  beta',
		'  anchor',
	}),
	'paste before must preserve an explicit register and count while adjusting indentation'
)

vim.fn.setreg('a', { 'alpha' }, 'V')
local yaml_buf = paste_buffer('yaml')
feedkeys('"ap')
check(
	vim.deep_equal(vim.api.nvim_buf_get_lines(yaml_buf, 0, -1, false), { '  anchor', 'alpha' }),
	'YAML paste must retain ordinary paste indentation and the explicit register'
)

assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: buffer refresh and native paste preserve Neovim semantics')

local gitsigns_plugin
for _, plugin in ipairs(dofile('lua/plugins/plugin_list.lua')) do
	if type(plugin) == 'table' and plugin[1] == 'lewis6991/gitsigns.nvim' then
		gitsigns_plugin = plugin
		break
	end
end
check(
	gitsigns_plugin and vim.deep_equal(gitsigns_plugin.event, { 'BufReadPre', 'BufNewFile' }),
	'Gitsigns must use lazy.nvim buffer events'
)

local reload_probe = scratch .. '/reload-probe.lua'
vim.fn.writefile({ 'vim.g.core_reload_probe = vim.g.core_reload_probe + 1' }, reload_probe)
vim.env.MYVIMRC = reload_probe
vim.g.core_reload_probe = 0
local config_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(config_buf, vim.fn.stdpath('config') .. '/synthetic.lua')
vim.api.nvim_exec_autocmds('BufWritePost', { buffer = config_buf })
check(vim.g.core_reload_probe == 0, 'writing config files must not source MYVIMRC')
check(vim.fn.exists(':restart') == 2, 'native :restart must be available as the reload path')

assert(#failures == 0, table.concat(failures, '\n'))
print('PASS: lazy.nvim events and native restart replace obsolete loaders')
