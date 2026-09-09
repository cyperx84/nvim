-- Collection of various small independent plugins/modules
local M = {}

M.specs = {
  { src = 'https://github.com/echasnovski/mini.nvim' },
}

function M.config()
  -- Keymaps (originally lazy.nvim `keys` triggers)
  -- MiniDiff
  vim.keymap.set('n', '<leader>td', function()
    require('mini.diff').toggle_overlay(0)
  end, { desc = 'Toggle MiniDiff' })
  -- Session Management (mini.sessions)
  vim.keymap.set('n', '<leader>Ss', function()
    vim.ui.input({ prompt = 'Session name: ' }, function(input)
      if input then
        require('mini.sessions').write(input)
        vim.notify('Session saved: ' .. input, vim.log.levels.INFO)
      end
    end)
  end, { desc = '[S]ession [S]ave' })
  vim.keymap.set('n', '<leader>Sh', function()
    vim.cmd '%bdelete'
    if vim.fn.exists ':Snacks' == 2 then
      Snacks.dashboard()
    end
  end, { desc = '[S]ession [H]ome (Dashboard)' })
  vim.keymap.set('n', '<leader>Sn', function()
    require('mini.sessions').read 'notes'
  end, { desc = '[S]ession open [N]otes' })
  vim.keymap.set('n', '<leader>Sd', function()
    require('mini.sessions').read 'dotfiles'
  end, { desc = '[S]ession open [D]otfiles' })
  vim.keymap.set('n', '<leader>Sc', function()
    require('mini.sessions').read 'code'
  end, { desc = '[S]ession open [C]ode' })
  vim.keymap.set('n', '<leader>Sl', function()
    require('mini.sessions').select 'read'
  end, { desc = '[S]ession [L]oad (select)' })
  vim.keymap.set('n', '<leader>Sr', function()
    vim.ui.input({ prompt = 'Session name to restore: ', default = 'notes' }, function(input)
      if input then
        require('mini.sessions').read(input)
      end
    end)
  end, { desc = '[S]ession [R]estore by name' })
  vim.keymap.set('n', '<leader>Sx', function()
    require('mini.sessions').select 'delete'
  end, { desc = '[S]ession delete (select)' })
  vim.keymap.set('n', '<leader>Sw', function()
    require('mini.sessions').write()
    vim.notify('Current session saved', vim.log.levels.INFO)
  end, { desc = '[S]ession [W]rite current' })

  -- Under lazy.nvim mini.nvim was `keys`-triggered, so none of these submodules
  -- were set up until a session/diff key was pressed. Set them up on UIEnter
  -- instead: keeps the work off the first-paint critical path (dashboard-only
  -- startups pay nothing) while ensuring text objects, the file explorer and
  -- session keymaps all work before any human keypress.
  require('pack').defer('UIEnter', function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()
    require('mini.sessions').setup {
      autoread = false, -- Keep false to always show dashboard on startup
      autowrite = true,
      directory = vim.fn.stdpath 'data' .. '/sessions',
      file = 'Session.vim',
      force = { read = false, write = true, delete = false },
      verbose = { read = true, write = true, delete = true },
    }
    -- NOTE: mini.statusline intentionally NOT set up here — lualine owns the
    -- statusline (plugins/lualine.lua). Under lazy.nvim both were keys/event
    -- deferred and whichever setup ran last won; mini ran last and silently
    -- shadowed the themed lualine config.
    -- mini.files + mini.colors setups removed: nothing in the config opened
    -- or consumed them (oil is the explorer; lualine's theme is a static
    -- table). Re-add here if you ever want them back.

    require('mini.pick').setup()
    require('mini.colors').setup()
    require('mini.diff').setup {
      view = {
        style = 'sign',
      },
    }
  end)
end

return M
-- vim: ts=2 sts=2 sw=2 et
