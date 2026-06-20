local M = {}

M.specs = {
  { src = 'https://github.com/folke/noice.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/rcarriga/nvim-notify' },
}

function M.config()
  -- Original lazy spec used event = 'VeryLazy'; defer setup until the UI is ready.
  require('pack').defer('UIEnter', function()
    vim.schedule(function()
      require('noice').setup {
        routes = {
          {
            filter = { event = 'notify', find = 'No information available' },
            opts = { skip = true },
          },
          {
            filter = { event = 'notify', find = 'Native terminal opened' },
            opts = { skip = true },
          },
        },
        presets = {
          lsp_doc_border = true,
        },
      }
    end)
  end)

  vim.keymap.set('n', '<leader>z', '<cmd>NoiceDismiss<CR>', { desc = 'Dismiss Noice Message' })
end

return M
