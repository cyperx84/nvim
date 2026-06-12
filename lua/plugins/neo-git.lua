local M = {}

M.specs = {
  { src = 'https://github.com/NeogitOrg/neogit', data = { lazy = true } },
  { src = 'https://github.com/sindrets/diffview.nvim', data = { lazy = true } },
  { src = 'https://github.com/echasnovski/mini.pick', data = { lazy = true } },
}

-- Keys-only under lazy.nvim, and the original spec had no opts/config, so
-- lazy never called setup(); we preserve that. The plugins stay off the
-- runtimepath until the first <leader>g* keypress loads them.
local function neogit(args)
  return function()
    require('pack').load { 'neogit', 'diffview.nvim', 'mini.pick' }
    vim.cmd('Neogit ' .. args)
  end
end

function M.config()
  vim.keymap.set('n', '<leader>gg', neogit 'kind=floating', { desc = 'Floating' })
  vim.keymap.set('n', '<leader>gG', neogit 'kind=split', { desc = 'Auto' })
  vim.keymap.set('n', '<leader>gb', neogit 'branch kind=auto', { desc = 'Branch' })
  vim.keymap.set('n', '<leader>gB', neogit 'branch_config kind=auto', { desc = 'Branch Config' })
  vim.keymap.set('n', '<leader>gc', neogit 'commit kind=auto', { desc = 'Commit' })
  vim.keymap.set('n', '<leader>gd', neogit 'diff kind=auto', { desc = 'Diff' })
  vim.keymap.set('n', '<leader>gl', neogit 'log kind=auto', { desc = 'Log' })
  vim.keymap.set('n', '<leader>gs', neogit 'stash kind=auto', { desc = 'Stash' })
  vim.keymap.set('n', '<leader>gm', neogit 'merge kind=auto', { desc = 'Merge' })
  vim.keymap.set('n', '<leader>gP', neogit 'pull', { desc = 'Pull' })
  vim.keymap.set('n', '<leader>gp', neogit 'push', { desc = 'Push' })
end

return M
