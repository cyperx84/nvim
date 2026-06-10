local M = {}

M.specs = {
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
}

function M.config()
  -- originally: event = { 'BufReadPost', 'BufNewFile' } -> eager per policy
  require('ibl').setup({})
end

return M
