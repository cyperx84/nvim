local M = {}

M.specs = {
  { src = 'https://github.com/ThePrimeagen/git-worktree.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
}

function M.config()
  require("git-worktree").setup({
    change_directory_command = "cd",
    update_on_change = true,
    update_on_change_command = "e .",
    clearjumps_on_change = true,
    autopush = false,
  })

  require("telescope").load_extension("git_worktree")

  vim.keymap.set("n", "<leader>gwl", function()
    require("telescope").extensions.git_worktree.git_worktrees()
  end, { desc = "List worktrees (C-d to delete)" })

  vim.keymap.set("n", "<leader>gwc", function()
    require("telescope").extensions.git_worktree.create_git_worktree()
  end, { desc = "Create worktree" })
end

return M
