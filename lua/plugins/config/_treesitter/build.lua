return function(plugin)
	-- Fresh installs need both the runtime path and a fresh module index.
	vim.opt.rtp:prepend(plugin.dir)
	require('lazy.core.cache').reset(plugin.dir)
	require('nvim-treesitter').update():wait(300000)
end
