local codecompanion_ok, codecompanion = pcall(require, 'codecompanion')

if not codecompanion_ok then
	return
end

codecompanion.setup({
	interactions = {
		chat = {
			adapter = {
				name = 'anthropic',
				model = 'claude-sonnet-4-20250514',
			},
		},
		inline = {
			adapter = 'anthropic',
		},
		cmd = {
			adapter = 'anthropic',
		},
		background = {
			adapter = {
				name = 'anthropic',
				model = 'claude-sonnet-4-20250514',
			},
		},
	},
	opts = {
		log_level = 'DEBUG',
	},
	adapters = {
		http = {
			anthropic = function()
				return require('codecompanion.adapters').extend('anthropic', {
					env = {
						api_key = os.getenv('ANTHROPIC_API_KEY'),
					},
				})
			end,
		},
	},
})
