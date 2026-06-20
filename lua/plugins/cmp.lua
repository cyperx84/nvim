local M = {}

M.specs = {
  {
    src = 'https://github.com/saghen/blink.cmp',
    -- lazy.nvim pin was version = '1.*' (release tags ship prebuilt fuzzy binaries)
    version = vim.version.range '1.*',
  },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
}

function M.config()
  require('blink.cmp').setup {
    keymap = { preset = 'default' },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      menu = {
        border = 'rounded',
        max_height = 20,
        winblend = 0,
        winhighlight = 'Normal:NONE,FloatBorder:TelescopeBorder,CursorLine:PmenuSel,Search:None',
      },
      documentation = {
        window = {
          border = 'rounded',
          winblend = 0,
          winhighlight = 'Normal:NONE,FloatBorder:TelescopeBorder',
        },
      },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      per_filetype = {
        codecompanion = { 'codecompanion' },
      },
    },

    fuzzy = { implementation = 'prefer_rust' },
  }
end

return M
