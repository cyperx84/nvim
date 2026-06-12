local M = {}

M.specs = {
  { src = 'https://github.com/ThePrimeagen/git-worktree.nvim', data = { lazy = true } },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
}

-- Keys-only under lazy.nvim; loaded, set up, and registered as a telescope
-- extension on the first <leader>gw* keypress. This also keeps telescope
-- itself off the startup path (requiring it here eagerly cost ~5ms).
local did_setup = false
local function worktrees()
  require('pack').load { 'git-worktree.nvim' }
  if not did_setup then
    did_setup = true
    require('git-worktree').setup {
      change_directory_command = 'cd',
      update_on_change = true,
      update_on_change_command = 'e .',
      clearjumps_on_change = true,
      autopush = false,
    }
    require('telescope').load_extension 'git_worktree'
  end
  return require('telescope').extensions.git_worktree
end

function M.config()
  vim.keymap.set('n', '<leader>gwl', function()
    worktrees().git_worktrees()
  end, { desc = 'List worktrees (C-d to delete)' })

  vim.keymap.set('n', '<leader>gwc', function()
    worktrees().create_git_worktree()
  end, { desc = 'Create worktree' })
end

return M
