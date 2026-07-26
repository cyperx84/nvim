---@diagnostic disable: undefined-global, undefined-doc-name, missing-fields
local M = {}

M.specs = {
  { src = 'https://github.com/NickvanDyke/opencode.nvim' },
  -- Recommended for `ask()` and `select()`.
  -- Required for `snacks` provider.
  ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
  { src = 'https://github.com/folke/snacks.nvim' },
}

-- Find the window holding the opencode terminal buffer.
local function find_opencode_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match 'opencode' then
        return win
      end
    end
  end
  return nil
end

-- Focus the opencode terminal window.
local function focus_opencode()
  local win = find_opencode_win()
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.notify('OpenCode terminal not found', vim.log.levels.WARN)
  end
end

-- Close the opencode terminal window.
local function close_opencode()
  local win = find_opencode_win()
  if win then
    vim.api.nvim_win_close(win, true)
  else
    vim.notify('OpenCode terminal not found', vim.log.levels.WARN)
  end
end

-- Add current buffer file as @reference.
local function add_current_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    vim.notify('No file in current buffer', vim.log.levels.WARN)
    return
  end
  require('opencode').prompt('@' .. bufname .. ' ')
end

-- Add all listed buffers as @references.
local function add_all_buffers()
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
    vim.notify('No valid buffers to send', vim.log.levels.WARN)
    return
  end

  for _, bufname in ipairs(valid_buffers) do
    require('opencode').prompt('@' .. bufname .. ' ')
  end
  vim.notify('Added ' .. #valid_buffers .. ' buffer(s)', vim.log.levels.INFO)
end

function M.config()
  -- snacks.nvim setup is owned by plugins/snacks.lua (under lazy.nvim this
  -- dep's empty opts tables merged into that config as a no-op).

  local opencode_cmd = 'opencode --port'
  ---@type snacks.terminal.Opts
  local opencode_terminal_opts = {
    win = {
      position = 'right',
      width = 0.35, -- 35% of screen
      enter = false,
      on_buf = function(self)
        -- snacks only auto-closes on exit 0; opencode exits non-zero on Ctrl+C
        vim.api.nvim_create_autocmd('TermClose', {
          buffer = self.buf,
          callback = function()
            self:close()
          end,
        })
      end,
    },
  }

  ---@type opencode.Opts
  vim.g.opencode_opts = {
    server = {
      start = function()
        require('snacks.terminal').open(opencode_cmd, opencode_terminal_opts)
      end,
    },
  }

  -- Required for `opts.events.reload`.
  vim.o.autoread = true

  -- ── Toggle ──────────────────────────────────────────────────────────
  vim.keymap.set({ 'n', 't' }, "<M-'>", function()
    require('snacks.terminal').toggle(opencode_cmd, opencode_terminal_opts)
  end, { desc = 'OpenCode Toggle' })
  vim.keymap.set('n', '<leader>Oo', function()
    require('snacks.terminal').toggle(opencode_cmd, opencode_terminal_opts)
  end, { desc = 'OpenCode Toggle' })

  -- ── Ask / Execute ───────────────────────────────────────────────────
  vim.keymap.set({ 'n', 'x' }, '<leader>Oa', function()
    require('opencode').ask '@this: '
  end, { desc = 'OpenCode Ask' })
  vim.keymap.set({ 'n', 'x' }, '<leader>Ox', function()
    require('opencode').select()
  end, { desc = 'OpenCode Execute action' })

  -- ── Window management ───────────────────────────────────────────────
  vim.keymap.set('n', '<leader>Of', focus_opencode, { desc = 'OpenCode Focus' })
  vim.keymap.set('n', '<leader>Oq', close_opencode, { desc = 'OpenCode Close' })

  -- ── Session management ──────────────────────────────────────────────
  vim.keymap.set('n', '<leader>On', function()
    require('opencode').command 'session.new'
  end, { desc = 'OpenCode New session' })
  vim.keymap.set('n', '<leader>Oj', function()
    require('opencode').command 'session.select'
  end, { desc = 'OpenCode Select session' })
  vim.keymap.set('n', '<leader>Om', function()
    require('opencode').command 'session.compact'
  end, { desc = 'OpenCode Compact session' })

  -- ── Agent ───────────────────────────────────────────────────────────
  vim.keymap.set('n', '<leader>Oc', function()
    require('opencode').command 'agent.cycle'
  end, { desc = 'OpenCode Cycle agent' })

  -- ── Send code ───────────────────────────────────────────────────────
  vim.keymap.set('v', '<leader>Os', function()
    require('opencode').prompt '@this '
  end, { desc = 'OpenCode Send selection' })
  vim.keymap.set('n', '<leader>OS', function()
    require('opencode').prompt '@this '
  end, { desc = 'OpenCode Send line' })

  -- ── Buffer management ───────────────────────────────────────────────
  vim.keymap.set('n', '<leader>Ob', add_current_buffer, { desc = 'OpenCode Add buffer' })
  vim.keymap.set('n', '<leader>OB', add_all_buffers, { desc = 'OpenCode Add all buffers' })

  -- ── Operator ────────────────────────────────────────────────────────
  vim.keymap.set({ 'n', 'x' }, 'go', function()
    return require('opencode').operator '@this '
  end, { expr = true, desc = 'Add range to opencode' })
  vim.keymap.set('n', 'goo', function()
    return require('opencode').operator '@this ' .. '_'
  end, { expr = true, desc = 'Add line to opencode' })
end

return M
