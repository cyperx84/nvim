local M = {}

M.specs = {
  { src = 'https://github.com/stevearc/dressing.nvim' },
}

function M.config()
  -- original lazy spec: event = 'VeryLazy'
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        require('dressing').setup {
          input = {
            enabled = true,
            default_prompt = 'Input',
            border = 'rounded',
            relative = 'cursor',
          },
          select = {
            enabled = true,
            backend = { 'telescope', 'builtin' },
            telescope = require('telescope.themes').get_dropdown(),
          },
        }
      end)
    end,
  })
end

return M
