return {
  {
    'loctvl842/monokai-pro.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'unokai'

      -- Color palette
      local colors = {
        border = '#0000ff',
        none = 'NONE',
      }

      -- Highlight groups that use border color
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
    'folke/tokyonight.nvim',
    lazy = true,
  },
}
