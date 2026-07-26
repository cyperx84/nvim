local M = {}

M.specs = {
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2', data = { lazy = true } },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
}

-- Keys-only under lazy.nvim; loaded and set up on the first harpoon keypress.
local did_setup = false
local function harpoon()
  require('pack').load { 'harpoon' }
  local h = require 'harpoon'
  if not did_setup then
    did_setup = true
    -- REQUIRED
    h:setup {
      settings = {
        save_on_toggle = true, -- apply menu edits when closing via toggle/q/Esc
      },
    }
  end
  return h
end

function M.config()
  -- Purple border on the harpoon menu only (remap FloatBorder for its window).
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'harpoon',
    callback = function(ev)
      vim.api.nvim_set_hl(0, 'HarpoonBorder', { fg = '#bb9af7' })
      local win = vim.fn.bufwinid(ev.buf)
      if win ~= -1 then
        vim.wo[win].winhighlight = 'FloatBorder:HarpoonBorder,FloatTitle:HarpoonBorder'
      end
    end,
  })

  vim.keymap.set('n', '<M-a>', function()
    harpoon():list():add()
  end, { desc = 'Harpoon: Mark File' })

  vim.keymap.set('n', '<M-e>', function()
    local h = harpoon()
    h.ui:toggle_quick_menu(h:list())
  end, { desc = 'Harpoon: Toggle Menu' })

  for i, key in ipairs { 'j', 'k', 'l', 'u', 'i', 'o', '7', '8', '9' } do
    vim.keymap.set('n', '<M-' .. key .. '>', function()
      harpoon():list():select(i)
    end, { desc = 'Harpoon File ' .. i })
  end
end

return M
