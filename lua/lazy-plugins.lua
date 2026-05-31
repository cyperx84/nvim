require('lazy').setup({
  { 'tpope/vim-sleuth', event = { 'BufReadPre', 'BufNewFile' } },
  { import = 'custom.plugins' },
}, {
  performance = {
    rtp = {
      -- Disable rarely-used built-in runtime plugins (oil/yazi replace netrw).
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'zipPlugin',
        'tohtml',
        'tutor',
        'netrwPlugin',
      },
    },
  },
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
  rocks = {
    enabled = false,
  },
})
-- vim: ts=2 sts=2 sw=2 et
