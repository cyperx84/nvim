return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- REQUIRED
    harpoon:setup()

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
