return {
	{ 'nvim-lua/plenary.nvim' },
	{ 'BurntSushi/ripgrep' },

	{
		'nvim-treesitter/nvim-treesitter',
		lazy = false,
		build = function(plugin)
			-- Fresh installs need both the runtime path and a fresh module index.
			vim.opt.rtp:prepend(plugin.dir)
			require('lazy.core.cache').reset(plugin.dir)
			require('nvim-treesitter').update():wait(300000)
		end,
		branch = 'main',
		config = function()
			require('plugins.config.treesitter')
		end,
	},

	{
		'kyazdani42/nvim-web-devicons',
		config = function()
			require('nvim-web-devicons').setup()
		end,
	},

	{
		'Shatur/neovim-session-manager',
		config = function()
			require('plugins.config.session_manager')
		end,
	},

	{
		'goolord/alpha-nvim',
		config = function()
			require('plugins.config.alpha')
		end,
	},

	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'kyazdani42/nvim-web-devicons' },
		config = function()
			require('plugins.config._lualine')
		end,
	},

	{
		'akinsho/bufferline.nvim',
		config = function()
			require('plugins.config._bufferline')
		end,
	},

	{
		'folke/snacks.nvim',
		priority = 1000,
		lazy = false,
		opts = {
			picker = { enabled = true },
			bigfile = { enabled = true },
			-- dashboard = { enabled = true },
			-- explorer = { enabled = true },
			-- indent = { enabled = true },
			-- input = { enabled = true },
			-- quickfile = { enabled = true },
			-- scope = { enabled = true },
			-- scroll = { enabled = true },
			-- statuscolumn = { enabled = true },
			-- words = { enabled = true },
		},
		keys = {
			{
				'<C-p>',
				function()
					Snacks.picker.resume()
				end,
				desc = 'Resume',
			},

			{
				'<leader>pp',
				function()
					Snacks.picker.smart({
						hidden = true,
						follow = false, -- Don't follow symlinks outside CWD
						cwd = vim.fn.getcwd(),
					})
				end,
				desc = 'Find Git Files',
			},
			{
				'<leader>pP',
				function()
					Snacks.picker.files({ hidden = true })
				end,
				desc = 'Find Files',
			},
			{
				'<leader>pw',
				function()
					Snacks.picker.grep({ hidden = true })
				end,
				desc = 'Grep',
			},
			{
				'<leader>pb',
				function()
					Snacks.picker.buffers()
				end,
				desc = 'Buffers',
			},
			{
				'<leader>pd',
				function()
					Snacks.picker.diagnostics()
				end,
				desc = 'Diagnostics',
			},
			{
				'<leader>pu',
				function()
					Snacks.picker.undo()
				end,
				desc = 'Undo History',
			},
			{
				'<leader>ph',
				function()
					Snacks.picker.help()
				end,
				desc = 'Help Pages',
			},

			{
				'<leader>pvc',
				function()
					Snacks.picker.command_history()
				end,
				desc = 'Command History',
			},
			{
				'<leader>pvh',
				function()
					Snacks.picker.highlights()
				end,
				desc = 'Highlights',
			},
			{
				'<leader>pvm',
				function()
					Snacks.picker.man()
				end,
				desc = 'Man Pages',
			},

			{
				'<leader>pgb',
				function()
					Snacks.picker.git_branches()
				end,
				desc = 'Git Branches',
			},
			{
				'<leader>pgl',
				function()
					Snacks.picker.git_log()
				end,
				desc = 'Git Log',
			},
			{
				'<leader>pgL',
				function()
					Snacks.picker.git_log_line()
				end,
				desc = 'Git Log Line',
			},
			{
				'<leader>pgs',
				function()
					Snacks.picker.git_status()
				end,
				desc = 'Git Status',
			},
			{
				'<leader>gpS',
				function()
					Snacks.picker.git_stash()
				end,
				desc = 'Git Stash',
			},
			{
				'<leader>gpd',
				function()
					Snacks.picker.git_diff()
				end,
				desc = 'Git Diff (Hunks)',
			},
			{
				'<leader>gpf',
				function()
					Snacks.picker.git_log_file()
				end,
				desc = 'Git Log File',
			},
			{
				'<leader>gpc',
				function()
					Snacks.picker.grep({
						title = 'Git Conflicts',
						search = '^<{7} ',
						regex = true,
						live = false,
					})
				end,
				desc = 'Git Conflicts',
			},
		},
		config = function()
			local colors = require('theme.colors')
			local utils = require('core.utils')

			local highlights = {
				-- SnacksPicker
				NormalFloat = { bg = colors.dark, fg = colors.light0 },

				SnacksBackdrop = { fg = colors.dark, bg = colors.dark, blend = 100 },

				SnacksPicker = { fg = colors.dark, bg = colors.dark },
				SnacksPickerBorder = { fg = colors.dark, bg = colors.dark },
				SnacksPickerInputBorder = { link = 'SnacksPickerBorder' },
				SnacksPickerDir = { fg = colors.light1 },
				SnacksPickerDirectory = { fg = colors.light1 },
				SnacksPickerFile = { fg = colors.light0 },
				SnacksPickerGitStatusAdded = { fg = colors.bright_green, bg = colors.dark },
				SnacksPickerGitStatusIgnored = { fg = colors.light4 },
				SnacksPickerGitStatusModified = { fg = colors.yellow },
				SnacksPickerGitStatusRenamed = { fg = colors.yellow },
				SnacksPickerGitStatusStaged = { fg = colors.green, bg = colors.dark },
				SnacksPickerGitStatusUnmerged = { fg = colors.orange },
				SnacksPickerGitStatusUntracked = { fg = colors.light2 },
				SnacksPickerInput = { link = 'NormalFloat' },
				SnacksPickerMatch = { fg = colors.bright_yellow, bg = colors.dark1, italic = true },
				SnacksPickerPathHidden = { fg = colors.light4 },
				SnacksPickerPrompt = { fg = colors.blue },
				SnacksPickerTitle = { fg = colors.aqua, bold = true },

				SnacksPickerListCursorLine = { link = 'CursorLine' },
				SnacksPickerPreviewCursorLine = { link = 'CursorLine' },

				SnacksPickerPreview = { bg = colors.dark0 },
				SnacksPickerPreviewBorder = { bg = colors.dark0, fg = colors.dark0 },
			}

			utils.set_highlights(highlights)
		end,
	},

	{
		'rcarriga/nvim-notify',
		dependencies = { 'kyazdani42/nvim-web-devicons' },
		config = function()
			require('plugins.config.notify')
		end,
	},

	{
		'folke/which-key.nvim',
		config = function()
			require('plugins.config.whichkey')
		end,
	},

	{
		'brooth/far.vim',
		config = function()
			require('plugins.config.far')
		end,
	},

	{
		'nvim-pack/nvim-spectre',
		config = function()
			require('plugins.config.spectre')
		end,
	},

	{
		'SirVer/ultisnips',
		config = function()
			require('plugins.config.ultisnips')
		end,
	},

	{
		'nvim-neotest/neotest',
		dependencies = {
			'nvim-lua/plenary.nvim',
			'antoinemadec/FixCursorHold.nvim',
			'nvim-treesitter/nvim-treesitter',
			'VladaTrefil/neotest-minitest',
			{
				'stevearc/overseer.nvim',
				config = function()
					require('overseer').setup()
				end,
			},
		},
		config = function()
			require('plugins.config._neotest')
		end,
	},

	{
		'olimorris/codecompanion.nvim',
		version = '^18.0.0',
		opts = {},
		dependencies = {
			'nvim-lua/plenary.nvim',
			'nvim-treesitter/nvim-treesitter',
		},
		config = function()
			require('plugins.config.codecompanion')
		end,
	},

	{
		'MeanderingProgrammer/render-markdown.nvim',
		ft = { 'markdown', 'codecompanion' },
		opts = {
			preview = {
				icon_provider = 'devicons',
			},
		},
		config = function()
			local colors = require('theme.colors')
			local utils = require('core.utils')

			local highlights = {
				RenderMarkdownCodeBlock = { bg = colors.dark0 },
				RenderMarkdownCode = { bg = colors.dark0 },
			}

			utils.set_highlights(highlights)
		end,
	},

	{ 'folke/lazydev.nvim' },

	{ 'folke/trouble.nvim' },

	{ 'onsails/lspkind.nvim' },
	-----

	{
		'mfussenegger/nvim-lint',
		lazy = true,
		event = 'BufAdd',
		config = function()
			require('plugins.config._lint')
		end,
	},

	{
		'stevearc/conform.nvim',
		lazy = true,
		event = 'BufWrite',
		config = function()
			require('plugins.config._conform')
		end,
	},

	{
		'hrsh7th/nvim-cmp',
		dependencies = {
			-- 'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-nvim-lua',
			'hrsh7th/cmp-buffer',
			'hrsh7th/cmp-path',
			'VladaTrefil/cmp-cmdline',
			'David-Kunz/cmp-npm',
			-- 'ray-x/cmp-treesitter', causes freeze when editing ('.') text
			'quangnguyen30192/cmp-nvim-ultisnips',
		},
		config = function()
			require('plugins.config.cmp')
		end,
	},

	{ 'drzel/vim-repo-edit' },
	{ 'tpope/vim-git' },
	{ 'tpope/vim-fugitive' },

	{
		'lewis6991/gitsigns.nvim',
		config = function()
			require('plugins.config._gitsigns')
		end,
	},

	{
		'folke/todo-comments.nvim',
		config = function()
			require('plugins.config._todo_comments')
		end,
	},

	{
		'sindrets/diffview.nvim',
		config = function()
			require('plugins.config._diffview')
		end,
	},

	{
		'echasnovski/mini.splitjoin',
		config = function()
			require('plugins.config._splitjoin')
		end,
	},

	{
		'windwp/nvim-autopairs',
		config = function()
			require('plugins.config.autopairs')
		end,
	},

	{
		'backdround/improved-search.nvim',
		config = function()
			require('plugins.config._improved_search')
		end,
	},

	---- this shit
	{ 'rhysd/clever-f.vim' },

	{
		'numToStr/Comment.nvim',
		config = function()
			require('plugins.config._comment')
		end,
	},

	{
		'lukas-reineke/indent-blankline.nvim',
		config = function()
			require('plugins.config._indentline')
		end,
	},

	{ 'RRethy/vim-illuminate' },

	{
		'norcalli/nvim-colorizer.lua',
		config = function()
			require('plugins.config._colorizer')
		end,
	},

	{ 'mattn/emmet-vim' },
	{ 'wavded/vim-stylus' },
	{ 'jasonshell/vim-svg-indent' },
	{ 'vim-scripts/svg.vim' },
	{ 'tpope/vim-eunuch' },
	{ 'mboughaba/i3config.vim' },
	{ 'kchmck/vim-coffee-script' },

	{
		'FabijanZulj/blame.nvim',
		lazy = false,
		config = function()
			require('blame').setup({})
		end,
	},
}
