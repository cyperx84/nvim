local M = {}

M.specs = {
  { src = 'https://github.com/folke/which-key.nvim' },
}

function M.config()
  -- Original lazy spec used event = 'VimEnter'; setup runs there.
  require('pack').defer('VimEnter', function()
    require('which-key').setup {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Only declare prefixes that actually have mappings behind them.
      -- Groups removed 2025-08: <leader>w/r had zero live mappings
      -- (verified against nvim_get_keymap at runtime). <leader>S and <leader>O
      -- hold real session/opencode keys and were previously undeclared.
      -- <leader>h came back 2026-08 when harpoon moved off the alt row.
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]iagnostic' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>S', group = '[S]essions' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>g', group = '[G]it' },
        { '<leader>h', group = '[H]arpoon' },
        { '<leader>O', group = '[O]penCode' },
        { '<leader>o', group = '[O]bsidian' },
        { '<leader>b', group = '[B]uffer' },
        { '<leader>q', group = '[Q]uickfix' },
        { '<leader>l', group = '[L]ocation List' },
      },
    }
  end)
end

return M
