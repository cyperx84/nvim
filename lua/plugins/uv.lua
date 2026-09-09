local M = {}

M.specs = {
  { src = 'https://github.com/benomahony/uv.nvim', data = { lazy = true } },
}

function M.config()
  -- Original lazy spec used event = 'VeryLazy'; defer setup until the UI is ready.
  require('pack').defer('UIEnter', function()
    vim.schedule(function()
      require('pack').load { 'uv.nvim' }
      require('uv').setup {
        -- Auto-activate virtual environments when found
        auto_activate_venv = true,

        -- Auto commands for directory changes
        auto_commands = true,

        -- Integration with snacks picker
        picker_integration = true,

        -- Keymaps to register (set to false to disable)
        keymaps = {
          prefix = '<leader>u', -- Main prefix for uv commands
          commands = true, -- Show uv commands menu (<leader>u)
          run_file = true, -- Run current file (<leader>ur)
          run_selection = true, -- Run selected code (<leader>us)
          run_function = true, -- Run function (<leader>uf)
          venv = true, -- Environment management (<leader>ue)
          init = true, -- Initialize uv project (<leader>ui)
          add = true, -- Add a package (<leader>ua)
          remove = true, -- Remove a package (<leader>ud)
          sync = true, -- Sync packages (<leader>uc)
          sync_all = true, -- Sync all packages, extras and groups (<leader>uC)
        },

        -- Execution options
        execution = {
          -- Python run command template
          run_command = 'uv run python',

          -- Show output in notifications
          notify_output = true,

          -- Notification timeout in ms
          notification_timeout = 10000,
        },
      }
    end)
  end)
end

return M
