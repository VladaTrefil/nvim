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
