return {
  {
    -- unokai is a Neovim built-in colorscheme; this entry exists only to run
    -- the custom highlight setup at startup with correct priority.
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'unokai'

      local colors = {
        border = '#0000ff',
        none = 'NONE',
      }

      local border_groups = {
        'WinSeparator',
        'FloatBorder',
        'TelescopeBorder',
        'TelescopePromptBorder',
        'TelescopeResultsBorder',
        'TelescopePreviewBorder',
      }

      local function set_custom_highlights()
        for _, group in ipairs(border_groups) do
          vim.api.nvim_set_hl(0, group, { fg = colors.border, bg = colors.none })
        end
        vim.api.nvim_set_hl(0, 'NormalFloat', { bg = colors.none })
      end

      set_custom_highlights()

      -- Re-apply after colorscheme changes only (not per-window/buffer)
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = set_custom_highlights,
      })
    end,
  },
  {
    'loctvl842/monokai-pro.nvim',
    lazy = true,
  },
}
