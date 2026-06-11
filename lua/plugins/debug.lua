local M = {}

M.specs = {
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/rcarriga/nvim-dap-ui' },
  { src = 'https://github.com/nvim-neotest/nvim-nio' },
  { src = 'https://github.com/williamboman/mason.nvim' },
  { src = 'https://github.com/jay-babu/mason-nvim-dap.nvim' },
  { src = 'https://github.com/leoluz/nvim-dap-go' },
}

-- The whole DAP stack was keys-only lazy under lazy.nvim and costs ~10ms to
-- set up (mason-nvim-dap alone is ~6ms), so keep it off the startup path:
-- keymaps are defined eagerly, setup runs on the first debug keypress.
local did_setup = false
local function ensure_setup()
  if did_setup then
    return
  end
  did_setup = true

  local dap = require 'dap'
  local dapui = require 'dapui'

  require('mason-nvim-dap').setup {
    automatic_installation = true,
    handlers = {},
    ensure_installed = {
      -- Update this to ensure that you have the debuggers for the langs you want
      'delve',
    },
  }
  dapui.setup {
    icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
    controls = {
      icons = {
        pause = '⏸',
        play = '▶',
        step_into = '⏎',
        step_over = '⏭',
        step_out = '⏮',
        step_back = 'b',
        run_last = '▶▶',
        terminate = '⏹',
        disconnect = '⏏',
      },
    },
  }

  -- Change breakpoint icons
  -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
  -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
  -- local breakpoint_icons = vim.g.have_nerd_font
  --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
  --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
  -- for type, icon in pairs(breakpoint_icons) do
  --   local tp = 'Dap' .. type
  --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
  --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
  -- end

  dap.listeners.after.event_initialized['dapui_config'] = dapui.open
  dap.listeners.before.event_terminated['dapui_config'] = dapui.close
  dap.listeners.before.event_exited['dapui_config'] = dapui.close
  -- Install golang specific config
  require('dap-go').setup {
    delve = {
      detached = vim.fn.has 'win32' == 0,
    },
  }
end

function M.config()
  vim.keymap.set('n', '<leader>ds', function()
    ensure_setup()
    require('dap').continue()
  end, { desc = 'Debug: Start/Continue' })
  vim.keymap.set('n', '<leader>di', function()
    ensure_setup()
    require('dap').step_into()
  end, { desc = 'Debug: Step Into' })
  vim.keymap.set('n', '<leader>do', function()
    ensure_setup()
    require('dap').step_over()
  end, { desc = 'Debug: Step Over' })
  vim.keymap.set('n', '<leader>du', function()
    ensure_setup()
    require('dap').step_out()
  end, { desc = 'Debug: Step Out' })
  vim.keymap.set('n', '<leader>b', function()
    ensure_setup()
    require('dap').toggle_breakpoint()
  end, { desc = 'Debug: Toggle Breakpoint' })
  vim.keymap.set('n', '<leader>B', function()
    ensure_setup()
    require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
  end, { desc = 'Debug: Set Breakpoint' })
  -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
  vim.keymap.set('n', '<leader>dd', function()
    ensure_setup()
    require('dapui').toggle()
  end, { desc = 'Debug: See last session result.' })
end

return M
