local M = {}

M.specs = {
  -- Messaging collapsed into snacks.notifier (snacks.lua): noice + nui +
  -- nvim-notify rendered messages through a second pipeline next to a snacks
  -- notifier that was itself switched off — three UIs for one job.
  -- Kept installed but off the runtimepath (data.lazy) for an easy flip-back
  -- window; delete this module once the notifier has settled in.
  { src = 'https://github.com/folke/noice.nvim', data = { lazy = true } },
  { src = 'https://github.com/MunifTanjim/nui.nvim', data = { lazy = true } },
  { src = 'https://github.com/rcarriga/nvim-notify', data = { lazy = true } },
}

return M
-- vim: ts=2 sts=2 sw=2 et
