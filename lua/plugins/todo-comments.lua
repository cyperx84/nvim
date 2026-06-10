-- Highlight todo, notes, etc in comments
local M = {}

M.specs = {
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
}

function M.config()
  -- Original lazy spec used event = 'VimEnter' → defer setup to UIEnter
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        require('todo-comments').setup({ signs = false })
      end)
    end,
  })
end

return M
-- vim: ts=2 sts=2 sw=2 et
