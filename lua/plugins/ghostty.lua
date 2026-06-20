local M = {}

-- Local plugin (dir=): Ghostty's bundled vimfiles — no vim.pack spec needed,
-- just add the directory to the runtimepath.
M.specs = {}

function M.config()
  vim.opt.rtp:append '/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/'
end

return M
