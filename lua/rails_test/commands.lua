local rt = require('rails_test')

vim.api.nvim_create_user_command('RailsTestNearest', rt.run_nearest, {})
vim.api.nvim_create_user_command('RailsTestFile', rt.run_file, {})
vim.api.nvim_create_user_command('RailsTestAll', rt.run_all, {})

vim.keymap.set('n', '<leader>tn', rt.run_nearest, { desc = 'Rails test: nearest' })
vim.keymap.set('n', '<leader>tf', rt.run_file, { desc = 'Rails test: file' })
vim.keymap.set('n', '<leader>ta', rt.run_all, { desc = 'Rails test: all' })
