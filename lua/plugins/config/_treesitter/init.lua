local ok, _ = pcall(require, 'nvim-treesitter')

if not ok then
	return
end

local FILETYPES = {
	'c',
	'lua',
	'luap',
	'javascript',
	'typescript',
	'rust',
	'ruby',
	'python',
	'bash',
	'scss',
	'slim',

	-- Markup
	'json',
	'yaml',
	'toml',
	'yuck',
	'rasi',
	'vimdoc',
	'dockerfile',
	'git_config',
	'gitignore',
}

require('nvim-treesitter').install(FILETYPES)

local INDENT_DISABLED = {
	slim = true,
	ruby = true,
}

vim.api.nvim_create_autocmd('FileType', {
	pattern = FILETYPES,
	callback = function(args)
		pcall(vim.treesitter.start)
		vim.wo.foldmethod = 'expr'
		vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
		if not INDENT_DISABLED[args.match] then
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})

vim.opt.foldlevel = 99
