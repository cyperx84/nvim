local M = {}

M.specs = {
  { src = 'https://github.com/windwp/nvim-autopairs' },
}

function M.config()
  -- Originally lazy-loaded on InsertEnter; preserve that trigger.
  vim.api.nvim_create_autocmd('InsertEnter', {
    once = true,
    callback = function()
      require('nvim-autopairs').setup {}
    end,
  })
end

return M
