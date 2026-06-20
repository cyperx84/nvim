local M = {}

M.specs = {
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}

function M.config()
  require('nvim-web-devicons').setup {}
end

return M
