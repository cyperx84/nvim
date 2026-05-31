return {
  'numToStr/Navigator.nvim',
  keys = {
    { '<C-h>', mode = { 'n', 't' } },
    { '<C-l>', mode = { 'n', 't' } },
    { '<C-k>', mode = { 'n', 't' } },
    { '<C-j>', mode = { 'n', 't' } },
  },
  config = function()
    require('Navigator').setup()
    vim.keymap.set({ 'n', 't' }, '<C-h>', '<CMD>NavigatorLeft<CR>')
    vim.keymap.set({ 'n', 't' }, '<C-l>', '<CMD>NavigatorRight<CR>')
    vim.keymap.set({ 'n', 't' }, '<C-k>', '<CMD>NavigatorUp<CR>')
    vim.keymap.set({ 'n', 't' }, '<C-j>', '<CMD>NavigatorDown<CR>')
  end
}
