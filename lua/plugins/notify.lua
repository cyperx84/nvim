local M = {}

M.specs = {
  { src = 'https://github.com/rcarriga/nvim-notify' },
}

function M.config()
  require('notify').setup {
    background_colour = '#000000', -- or "NotifyBackground" if using a highlight group
    stages = 'fade_in_slide_out',
    timeout = 3000,
    fps = 60,
    render = 'compact',
  }
  vim.notify = require 'notify' -- make it the default notification system

  vim.keymap.set('n', '<leader>sl', '<cmd>Telescope notify<CR>', { desc = '[S]earch Notify [L]og' })
end

return M
