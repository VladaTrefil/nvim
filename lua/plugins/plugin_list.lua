return {
	{ 'nvim-lua/plenary.nvim' },
	{ 'BurntSushi/ripgrep' },

	{
		'nvim-treesitter/nvim-treesitter',
		lazy = false,
		build = require('plugins.config._treesitter.build'),
		branch = 'main',
		config = function()
			require('plugins.config._treesitter')
		end,
	},

	{
		'kyazdani42/nvim-web-devicons',
		config = function()
			require('plugins.config._web_devicons')
		end,
	},

	{
		'Shatur/neovim-session-manager',
		config = function()
			require('plugins.config._session_manager')
		end,
	},

	{
		'goolord/alpha-nvim',
		config = function()
			require('plugins.config._alpha')
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
			require('plugins.config._snacks')
		end,
	},

	{
		'rcarriga/nvim-notify',
		dependencies = { 'kyazdani42/nvim-web-devicons' },
		config = function()
			require('plugins.config._notify')
		end,
	},

	{
		'folke/which-key.nvim',
		config = function()
			require('plugins.config._whichkey')
		end,
	},

	{
		'nvim-pack/nvim-spectre',
		config = function()
			require('plugins.config._spectre')
		end,
	},

	{
		'SirVer/ultisnips',
		config = function()
			require('plugins.config._ultisnips')
		end,
	},

	{
		'nvim-neotest/neotest',
		dependencies = {
			'nvim-neotest/nvim-nio',
			'antoinemadec/FixCursorHold.nvim',
		},
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
			require('plugins.config._codecompanion')
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
			require('plugins.config._render_markdown')
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
		event = 'BufWritePre',
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
			require('plugins.config._cmp')
		end,
	},

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
			require('plugins.config._autopairs')
		end,
	},

	{
		'backdround/improved-search.nvim',
		config = function()
			require('plugins.config._improved_search')
		end,
	},

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

	{ 'jasonshell/vim-svg-indent' },
	{ 'vim-scripts/svg.vim' },
	{ 'tpope/vim-eunuch' },
	{ 'mboughaba/i3config.vim' },

	{
		'FabijanZulj/blame.nvim',
		lazy = false,
		config = function()
			require('plugins.config._blame')
		end,
	},
}
