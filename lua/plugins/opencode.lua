---@diagnostic disable: undefined-global, undefined-doc-name, missing-fields
local M = {}

M.specs = {
  { src = 'https://github.com/NickvanDyke/opencode.nvim' },
  -- Recommended for `ask()` and `select()`.
  -- Required for `snacks` provider.
  ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
  { src = 'https://github.com/folke/snacks.nvim' },
}

function M.config()
  -- snacks.nvim setup is owned by plugins/snacks.lua (under lazy.nvim this
  -- dep's empty opts tables merged into that config as a no-op).

  local opencode_cmd = "opencode --port"
  ---@type snacks.terminal.Opts
  local opencode_terminal_opts = {
    win = {
      position = "right",
      width = 0.35, -- 35% of screen
      enter = false,
      on_buf = function(self)
        -- snacks only auto-closes on exit 0; opencode exits non-zero on Ctrl+C
        vim.api.nvim_create_autocmd("TermClose", {
          buffer = self.buf,
          callback = function() self:close() end,
        })
      end,
    },
  }

  ---@type opencode.Opts
  vim.g.opencode_opts = {
    server = {
      start = function()
        require("snacks.terminal").open(opencode_cmd, opencode_terminal_opts)
      end,
    },
  }

  -- Required for `opts.events.reload`.
  vim.o.autoread = true

  -- OpenCode keymaps (using <leader>O to avoid conflicts)
  vim.keymap.set({ "n", "x" }, "<leader>Oa", function() require("opencode").ask("@this: ") end, { desc = "OpenCode Ask" })
  vim.keymap.set({ "n", "x" }, "<leader>Ox", function() require("opencode").select() end,       { desc = "OpenCode Execute action" })
  vim.keymap.set({ "n", "t" }, "<M-'>", function() require("snacks.terminal").toggle(opencode_cmd, opencode_terminal_opts) end, { desc = "OpenCode Toggle" })

  vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { expr = true, desc = "Add range to opencode" })
  vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { expr = true, desc = "Add line to opencode" })
end

return M
