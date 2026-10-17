local M = {}

local cmp = require('cmp')

vim.cmd([[inoremap <silent> <Plug>(cmp-literal-tab) <Tab>]])
vim.cmd([[inoremap <silent> <Plug>(cmp-literal-stab) <S-Tab>]])

local feed = function(plug)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(plug, true, true, true), 'm', true)
end

local on_confirm = function()
	if vim.fn['UltiSnips#CanExpandSnippet']() == 1 then
		feed('<Plug>(cmpu-expand)')
	elseif vim.fn['UltiSnips#CanJumpForwards']() == 1 then
		feed('<Plug>(cmpu-jump-forwards)')
	elseif cmp.visible() then
		cmp.confirm({ select = true })
	else
		feed('<Plug>(cmp-literal-tab)')
	end
end

local on_confirm_inverse = function()
	if vim.fn['UltiSnips#CanJumpBackwards']() == 1 then
		feed('<Plug>(cmpu-jump-backwards)')
	else
		feed('<Plug>(cmp-literal-stab)')
	end
end

local common = {
	-- add function for switch between docs and completion
	['<C-n>'] = vim.NIL,
	['<C-p>'] = vim.NIL,
	['<C-u>'] = cmp.mapping.scroll_docs(-4),
	['<C-d>'] = cmp.mapping.scroll_docs(4),
	['<C-e>'] = cmp.mapping(cmp.mapping.abort(), { 'i', 'c', 's' }),
	['<Tab>'] = cmp.mapping(on_confirm, { 'i', 'c', 's' }),
	['<S-Tab>'] = cmp.mapping(on_confirm_inverse, { 'i', 's' }),
}

M.editor = vim.tbl_deep_extend('force', common, {
	['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c', 's' }),
	['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c', 's' }),
})

M.cmdline = vim.tbl_deep_extend('force', common, {
	['<C-j>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c', 's' }),
	['<C-k>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c', 's' }),
})

return M
