-- Basic LSP setup for Neovim 0.11+ with ESLint and RuboCop
-- Place this in ~/.config/nvim/lua/lsp-config.lua and require it from init.lua

local lsp = vim.lsp
local api = vim.api

local utils = require('core.utils')

-- Set up diagnostic display
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	float = {
		border = 'rounded',
		source = 'always',
	},
})

-- LSP keymaps (set when LSP attaches)
local function on_attach(client, bufnr)
	local opts = { buffer = bufnr, silent = true }

	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
	vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
	vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
	vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
	vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
	vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
	vim.keymap.set('n', '<leader>f', function()
		vim.lsp.buf.format({ async = true })
	end, opts)
	vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
	vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
	vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
end

-- Auto-start ESLint for relevant filetypes
api.nvim_create_autocmd('FileType', {
	pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue', 'svelte' },
	callback = function(args)
		if vim.fn.executable('vscode-eslint-language-server') ~= 1 then
			return
		end

		if utils.filesize_kb() > 50 then
			return
		end

		local root_dir = vim.fs.root(args.buf, {
			'.eslintrc',
			'.eslintrc.js',
			'.eslintrc.cjs',
			'.eslintrc.json',
			'.eslintrc.yaml',
			'.eslintrc.yml',
			'eslint.config.js',
			'eslint.config.mjs',
			'eslint.config.cjs',
		})

		if not root_dir then
			return
		end

		lsp.start({
			name = 'eslint',
			cmd = { 'vscode-eslint-language-server', '--stdio' },
			root_dir = root_dir,
			on_attach = on_attach,
			capabilities = vim.lsp.protocol.make_client_capabilities(),
			settings = {
				codeAction = {
					disableRuleComment = {
						enable = true,
						location = 'separateLine',
					},
					showDocumentation = {
						enable = true,
					},
				},
				codeActionOnSave = {
					enable = false,
					mode = 'all',
				},
				experimental = {},
				format = true,
				nodePath = '',
				onIgnoredFiles = 'off',
				packageManager = 'npm',
				problems = {
					shortenToSingleLine = false,
				},
				quiet = false,
				rulesCustomizations = {},
				run = 'onType',
				useESLintClass = false,
				validate = 'on',
				workingDirectory = {
					mode = 'location',
				},
			},
			handlers = {
				['eslint/openDoc'] = function(_, result)
					if result then
						vim.ui.open(result.url)
					end
					return {}
				end,
				['eslint/confirmESLintExecution'] = function()
					return 4 -- approved
				end,
				['eslint/probeFailed'] = function()
					vim.notify('ESLint probe failed', vim.log.levels.WARN)
					return {}
				end,
				['eslint/noLibrary'] = function()
					vim.notify('ESLint library not found', vim.log.levels.WARN)
					return {}
				end,
			},
		})
	end,
})

-- Auto-start RuboCop for Ruby files
api.nvim_create_autocmd('FileType', {
	pattern = 'ruby',
	callback = function(args)
		if vim.fn.executable('rubocop') ~= 1 then
			return
		end

		local root_dir = vim.fs.root(args.buf, { '.rubocop.yml', 'Gemfile', '.git' })

		if not root_dir then
			return
		end

		lsp.start({
			name = 'rubocop',
			cmd = { 'rubocop', '--lsp' },
			root_dir = root_dir,
			on_attach = on_attach,
			capabilities = vim.lsp.protocol.make_client_capabilities(),
		})
	end,
})

-- Diagnostic signs
local signs = { Error = '✘', Warn = '▲', Hint = '⚑', Info = '»' }
for type, icon in pairs(signs) do
	local hl = 'DiagnosticSign' .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
