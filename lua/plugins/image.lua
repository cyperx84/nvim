local M = {}

M.specs = {
  { src = 'https://github.com/HakonHarnes/img-clip.nvim', data = { lazy = true } },
}

-- Keys-only under lazy.nvim; loaded and set up on first use.
local function paste_image()
  require('pack').load { 'img-clip.nvim' }
  require('img-clip').setup {
    filetypes = {
      codecompanion = {
        prompt_for_file_name = false,
        template = '[Image]($FILE_PATH)',
        use_absolute_path = true,
      },
    },
  }
  vim.cmd.PasteImage()
end

function M.config()
  vim.keymap.set('n', '<leader>pi', paste_image, { desc = 'Paste Image' })
end

return M
