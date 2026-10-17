local utils = require('core.utils')

vim.api.nvim_create_user_command('FormatXML', function()
	utils.format_xml(0)
end, {
	desc = 'Expand and indent XML tags',
	force = true,
})

function _G.ReloadConfig()
	for name, _ in pairs(package.loaded) do
		if name:match('^user') and not name:match('nvim-tree') then
			package.loaded[name] = nil
		end
	end

	dofile(vim.env.MYVIMRC)

	vim.notify('Nvim configuration reloaded!', vim.log.levels.INFO)
end

function _G.foldtext()
	return utils.fold_label_text()
end
