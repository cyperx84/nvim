-- Toggle Claude Code without moving cursor focus
local function toggle_claude_no_focus()
  local current_win = vim.api.nvim_get_current_win()
  local ok, err = pcall(vim.cmd, 'ClaudeCode')
  if not ok then
    vim.notify('Error launching Claude Code: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
    return
  end
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(current_win) and vim.api.nvim_get_current_win() ~= current_win then
      vim.api.nvim_set_current_win(current_win)
    end
  end, 50)
end

local function add_current_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    vim.notify('No file in current buffer', vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(require('claudecode').send_at_mention, bufname, nil, nil)
  if ok then
    vim.notify('Added buffer to Claude Code', vim.log.levels.INFO)
  else
    vim.notify('Error adding buffer: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
  end
end

local function send_all_buffers()
  local valid_buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname ~= '' and not bufname:match '^term://' then
        table.insert(valid_buffers, bufname)
      end
    end
  end

  if #valid_buffers == 0 then
    vim.notify('No valid buffers to send to Claude Code', vim.log.levels.WARN)
    return
  end

  local claudecode = require 'claudecode'
  for _, bufname in ipairs(valid_buffers) do
    local ok, err = pcall(claudecode.send_at_mention, bufname, nil, nil)
    if not ok then
      vim.notify('Error adding buffer ' .. bufname .. ': ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
    end
  end
  vim.notify('Added ' .. #valid_buffers .. ' buffer(s) to Claude Code', vim.log.levels.INFO)
end

local M = {}

M.specs = {
  { src = 'https://github.com/coder/claudecode.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
}

function M.config()
  -- Setup deferred past first paint: requiring claudecode costs ~8ms and the
  -- plugin is only ever reached via keymaps, so VimEnter (pre-paint) was
  -- needlessly on the critical path. UIEnter + schedule still runs well
  -- before any human keypress.
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = vim.schedule_wrap(function()
      -- Resolve the claude binary per-machine instead of hardcoding one path:
      -- it's ~/.local/bin/claude on some boxes, /opt/homebrew/bin/claude
      -- (Homebrew) on others. exepath() finds whatever is on nvim's PATH; fall
      -- back to the ~/.local/bin location if it isn't on PATH.
      local claude_bin = vim.fn.exepath 'claude'
      if claude_bin == '' then
        claude_bin = vim.fn.expand '~/.local/bin/claude'
      end

      local opts = {
        -- `env -u TMUX -u TMUX_PANE`: Claude Code downgrades itself to 256-color
        -- whenever it sees $TMUX (washes the mascot/colors). This launches the
        -- binary directly, bypassing the shell alias that handles it elsewhere,
        -- so strip $TMUX here too to keep true 24-bit color.
        terminal_cmd = 'env -u TMUX -u TMUX_PANE ' .. claude_bin .. ' --dangerously-skip-permissions',

        port_range = { min = 10000, max = 65535 },
        auto_start = true,
        log_level = 'warn',

        terminal = {
          split_side = 'right',
          provider = 'snacks',
          auto_close = true,
          split_width_percentage = 0.35,
          cwd_provider = function(ctx)
            local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(ctx.file_dir) .. ' rev-parse --show-toplevel')[1]
            if vim.v.shell_error == 0 and git_root then
              return git_root
            end
            return ctx.file_dir
          end,
        },

        diff_opts = {
          auto_close_on_accept = true,
          vertical_split = true,
          open_in_current_tab = true,
          keep_terminal_focus = true,
        },
      }

      require('claudecode').setup(opts)

      local group = vim.api.nvim_create_augroup('ClaudeCodeAutoread', { clear = true })
      vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
        group = group,
        callback = function()
          if vim.fn.mode() ~= 'c' then
            vim.cmd 'checktime'
          end
        end,
      })

      vim.opt.autoread = true
    end),
  })

  -- Keymaps (always eager)
  -- Core Claude Code commands
  vim.keymap.set('n', '<M-;>', '<cmd>ClaudeCode<cr>', { desc = 'Toggle Claude' })
  vim.keymap.set('t', '<M-;>', toggle_claude_no_focus, { desc = 'Toggle Claude (close)' })
  vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<cr>', { desc = 'Toggle Claude' })
  vim.keymap.set('n', '<leader>cf', '<cmd>ClaudeCodeFocus<cr>', { desc = 'Focus Claude' })
  vim.keymap.set('n', '<leader>cm', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'Select Claude model' })

  -- Session management
  vim.keymap.set('n', '<leader>cr', '<cmd>ClaudeCode --resume<cr>', { desc = 'Resume Claude' })
  vim.keymap.set('n', '<leader>cC', '<cmd>ClaudeCode --continue<cr>', { desc = 'Continue Claude' })

  -- File/content management
  vim.keymap.set('n', '<leader>cb', add_current_buffer, { desc = 'Add current buffer' })
  vim.keymap.set('n', '<leader>cB', send_all_buffers, { desc = 'Add all buffers to Claude' })
  vim.keymap.set('v', '<leader>cs', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send selection to Claude' })
  vim.keymap.set('n', '<leader>cS', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send current line to Claude' })

  -- Tree/file explorer integration
  -- (the original key was ft-scoped, so it becomes a buffer-local mapping for those filetypes)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'NvimTree', 'neo-tree', 'oil', 'minifiles' },
    callback = function(ev)
      vim.keymap.set('n', '<leader>ca', '<cmd>ClaudeCodeTreeAdd<cr>', { desc = 'Add file from tree', buffer = ev.buf })
    end,
  })

  -- Quick actions
  vim.keymap.set('n', '<leader>c?', '<cmd>help claudecode<cr>', { desc = 'Claude Code help' })
  vim.keymap.set('n', '<leader>cq', '<cmd>ClaudeCodeClose<cr>', { desc = 'Close Claude Code' })
end

return M
