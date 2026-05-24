return {
  'saghen/blink.cmp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',
  config = function(_, opts)
    require('blink.cmp').setup(opts)
  end,
  opts = {
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
  },
  opts_extend = { 'sources.default' },
}
