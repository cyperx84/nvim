local M = {}

M.specs = {
  { src = 'https://github.com/HakonHarnes/img-clip.nvim' },
}

function M.config()
  require('img-clip').setup({
    filetypes = {
      codecompanion = {
        prompt_for_file_name = false,
        template = '[Image]($FILE_PATH)',
        use_absolute_path = true,
      },
    },
  })

  vim.keymap.set('n', '<leader>pi', '<cmd>PasteImage<CR>', { desc = 'Paste Image' })
end

return M
