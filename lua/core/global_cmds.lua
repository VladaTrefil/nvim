local utils = require('core.utils')

vim.api.nvim_create_user_command('FormatXML', function()
	utils.format_xml(0)
end, {
	desc = 'Expand and indent XML tags',
	force = true,
})

function _G.foldtext()
	return utils.fold_label_text()
end
