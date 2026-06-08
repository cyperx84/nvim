return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    '<M-a>', '<M-e>',
    '<M-j>', '<M-k>', '<M-l>',
    '<M-u>', '<M-i>', '<M-o>',
    '<M-7>', '<M-8>', '<M-9>',
  },
  config = function()
    local harpoon = require 'harpoon'

    -- REQUIRED
    harpoon:setup({
      settings = {
        save_on_toggle = true, -- apply menu edits when closing via toggle/q/Esc
      },
    })

    vim.keymap.set('n', '<M-a>', function()
      harpoon:list():add()
    end, {
      desc = 'Harpoon: Mark File',
    })

    vim.keymap.set('n', '<M-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, {
      desc = 'Harpoon: Toggle Menu',
    })

    for i, key in ipairs { 'j', 'k', 'l', 'u', 'i', 'o', '7', '8', '9' } do
      vim.keymap.set('n', '<M-' .. key .. '>', function()
        harpoon:list():select(i)
      end, {
        desc = 'Harpoon File ' .. i,
      })
    end
  end,
}
