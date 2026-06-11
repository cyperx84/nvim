local M = {}

M.specs = {
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
}

function M.config()
  -- Originally event = { 'BufReadPost', 'BufNewFile' } under lazy.nvim;
  -- same deferral so dashboard-only startups skip the setup cost.
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    once = true,
    callback = function()
      require('ibl').setup({})
    end,
  })
end

return M
