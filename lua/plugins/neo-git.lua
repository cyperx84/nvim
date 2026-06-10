local M = {}

M.specs = {
  { src = 'https://github.com/NeogitOrg/neogit' },
  { src = 'https://github.com/sindrets/diffview.nvim' },
  { src = 'https://github.com/echasnovski/mini.pick' },
}

function M.config()
  -- Original lazy spec had no opts/config, so lazy.nvim never called setup();
  -- we preserve that: keymaps only. The :Neogit command is provided by the
  -- plugin's plugin/ files, which source after init.lua.
  vim.keymap.set('n', '<leader>gg', '<cmd>Neogit kind=floating<CR>', { desc = 'Floating' })
  vim.keymap.set('n', '<leader>gG', '<cmd>Neogit kind=split<CR>', { desc = 'Auto' })
  vim.keymap.set('n', '<leader>gb', '<cmd>Neogit branch kind=auto<CR>', { desc = 'Branch' })
  vim.keymap.set('n', '<leader>gB', '<cmd>Neogit branch_config kind=auto<CR>', { desc = 'Branch Config' })
  vim.keymap.set('n', '<leader>gc', '<cmd>Neogit commit kind=auto<CR>', { desc = 'Commit' })
  vim.keymap.set('n', '<leader>gd', '<cmd>Neogit diff kind=auto<CR>', { desc = 'Diff' })
  vim.keymap.set('n', '<leader>gl', '<cmd>Neogit log kind=auto<CR>', { desc = 'Log' })
  vim.keymap.set('n', '<leader>gs', '<cmd>Neogit stash kind=auto<CR>', { desc = 'Stash' })
  vim.keymap.set('n', '<leader>gm', '<cmd>Neogit merge kind=auto<CR>', { desc = 'Merge' })
  vim.keymap.set('n', '<leader>gP', '<cmd>Neogit pull<CR>', { desc = 'Pull' })
  vim.keymap.set('n', '<leader>gp', '<cmd>Neogit push<CR>', { desc = 'Push' })
end

return M
