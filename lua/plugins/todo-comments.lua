-- Highlight todo, notes, etc in comments
local M = {}

M.specs = {
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
}

function M.config()
  -- Original lazy spec used event = 'VimEnter' → setup runs there
  require('pack').defer('VimEnter', function()
    require('todo-comments').setup { signs = false }
  end)
end

return M
-- vim: ts=2 sts=2 sw=2 et
